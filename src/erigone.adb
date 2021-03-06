--
--               The Erigone Model Checker
--       Copyright 2008-9 by Mordechai (Moti) Ben-Ari.
--
--       The compiler was written by Trishank Karthik Kuppusamy
--       under the supervision of Edmond Schonberg.
-- 
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
-- This program is distributed in the hope that it will be useful
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
-- 02111-1307, USA.
--
--
--  Main program
--
with Ada.Text_IO, Ada.Exceptions;
with Arguments, Automata.Display, Compile_Global, Execute, Files;
with LTL, Options, Symbol_Tables, Times, Utilities;
procedure Erigone is
  use type Options.Execution_Type, Options.LTL_Type;
  Automata_File: Ada.Text_IO.File_Type;
begin
  Times.Start;
  Options.Set_Defaults;
  Symbol_Tables.Initialize;
  Automata.Initialize;

  -- Set arguments in Options and file name in Files
  if not Arguments.Get_Arguments then return; end if;

  -- LTL2BA only
  if Options.Execution_Mode = Options.LTL_Only then
    LTL.LTL_To_Automaton(Files.LTL_File_Name.all);
    Times.End_Compile;
    Times.Print_Times;
    return;
  end if;

  -- Compile
  Compile_Global.Compile_File(
    Files.Source_File_Name.all,
    Files.Automata_File_Name.all,
    Options.Compiler_Logs);

  -- Read automata file
  Ada.Text_IO.Open(
    Automata_File, Ada.Text_IO.In_File, Files.Automata_File_Name.all);
  Symbol_Tables.Read(Automata_File);
  Automata.Read(Automata_File);

  -- Translate LTL to BA and store in Automata table
  if Options.LTL_Mode = Options.File and
       Options.Execution_Mode /= Options.Simulation then
    Automata.Translate_LTL;
  end if;

  -- Insert constants as immediate operands
  Symbol_Tables.Fix_Load_Constant;
  Automata.Fix_Load_Constant;

  -- Display automata only after translation of LTL to never claim
  Symbol_Tables.Put_Symbol_Table;
  Automata.Display.Put_Automata;

  Times.End_Compile;

  -- Compile only
  if Options.Execution_Mode = Options.Compile_Only then
    Times.Print_Times;
    return;
  end if;

  -- Execute simulation or verification
  Execute.Run;
  Times.End_Execute;
  Times.Print_Times;
exception
  when E: others =>
    Ada.Text_IO.Put_Line(
      "exception=" & 
      Utilities.To_Lower(Ada.Exceptions.Exception_Name(E)) & ",");
    Ada.Text_IO.Put_Line(
      "message="  &  Ada.Exceptions.Exception_Message(E) & ",");
end Erigone;
