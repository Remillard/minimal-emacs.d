;;; vhdl-mode-config.el --- VHDL Mode Configuration -*- no-byte-compile: t; lexical-binding: t; -*-

;; Author: Mark Norton
;; URL: https://github.com/remillard/minimal-emacs.d
;; Package-Requires: ((emacs "29.1"))

;;; Commentary
;; Splitting the specific VHDL Mode configuration into its own file to declutter
;; the `post-init.el' file a bit, as it's already rather large with the
;; package selection and configurations.

(add-to-list 'load-path "~/.emacs.d/site-lisp/vhdl-mode-3.39.3/")
(autoload 'vhdl-mode "vhdl-mode" "VHDL Mode" t)
(setq auto-mode-alist (cons '("\\.vhdl?\\'" . vhdl-mode) auto-mode-alist))
(require 'vhdl-mode)

(setopt vhdl-model-alist
        '(("Example Model" "<label> : process (<clock>, <reset>)\12begin  -- process <label>\12  if <reset> = '0' then  -- asynchronous reset (active low)\12    <cursor>\12  elsif <clock>'event and <clock> = '1' then  -- rising clock edge\12    if <enable> = '1' then  -- synchronous load\12\12    end if;\12  end if;\12end process <label>;" "" "")
          ("Sync Process w/ Sync Reset" "<label> : process (<clock>, <reset>)\12begin  -- process <label>\12    if rising_edge(<clock>) then            -- rising clock edge\12        if (<reset> = '1') then           -- synchronous reset (active high)\12            <cursor>\12        else/elsif\12            \12        end if;\12    end if;\12end process <label>;" "s" "spsr")
          ("Sync Process w/ Async Reset" "<label> : process (<clock>, <reset>)\12begin  -- process <label>\12    if (<reset> = '1') then               -- asyncronous reset (active high)\12        <cursor>\12    elsif rising_edge(<clock>) then         -- rising clock edge\12        \12    end if;\12end process <label>;" "a" "spar")
          ("Combinatorial Process" "<label> : process (all)\12begin  -- process <label>\12    <cursor>\12end process <label>;" "c" "cp")
          ("Testbench Process (no sensitivity list)" "<label> : process\12begin  -- process <label>\12    <cursor>\12end process <label>;" "t" "tp")
          ("Shorthand std_logic_vector" "std_logic_vector(<cursor>)" "" "slv")
          ("Basic IEEE Libraries" "library ieee;\12use ieee.std_logic_1164.all\12use ieee.numeric_std.all;\12<cursor>" "" "ieee")
          ("TextIO Libraries" "use std.textio.all\12use ieee.std_logic_textio.all;\12<cursor>" "" "textio")))

;; Projects
(require 'local-vhdl-proj)

(setopt vhdl-basic-offset 4
        vhdl-electric-mode t
        vhdl-indent-tabs-mode nil
        vhdl-project nil
        vhdl-stutter-mode t
        vhdl-array-index-record-field-in-sensitivity-list nil
        vhdl-clock-name "clk"
        vhdl-clock-edge-condition 'function
        vhdl-conditions-in-parenthesis t
        vhdl-date-format "%a %b %e %H:%M:%S %Y"
        vhdl-end-comment-column 80
        vhdl-reset-active-high t
        vhdl-reset-name "reset"
        vhdl-standard '(8 nil)
        vhdl-underscore-is-part-of-word t
        vhdl-upper-case-enum-values t
        vhdl-use-direct-instantiation 'always
        vhdl-compiler "ModelSim"
        vhdl-platform-spec "Sim: Questasim, Synth: Vendor Toolchain (Quartus/Vivado)"
        vhdl-instance-name (cons ".*" "u_\\&_%d"))

(setopt vhdl-company-name local-vhdl-company-name)
;;
;; Sets the closing parenthesis to be back one indent level which is not the
;; shipping standard for vhdl-mode.  This function hooks the set offset for
;; the closing argument list and sets it to 0 levels of indentation.
;;
(add-hook 'vhdl-mode-hook
          (lambda ()
            (vhdl-set-offset 'arglist-close 0)))
;;
;; Makes compilation buffer show up horizontal low
;;
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*$" . (display-buffer-below-selected)))
;;
;; Setting up preferred header string
;;
(setopt vhdl-modify-date-prefix-string "-- Last update : ")
(setopt vhdl-copyright-string "Copyright <year> by Garmin Ltd. or its subsidiaries")
(setopt vhdl-file-header "\
-------------------------------------------------------------------------------
--
-- Entity      : <title string>
-- Project     : <project>
-- Author      : <author>
-- Created     : <date>
-- Company     : <company>
-- Copyright   : <copyright>
-- Repo        :
-- Directory   :
-- File        : <filename>
-- Standard    : <standard>
--
-------------------------------------------------------------------------------
-- Description: <cursor>
-------------------------------------------------------------------------------
-- Hierarchy By Level:
-------------------------------------------------------------------------------
-- Naming Conventions used:
-- Active Low:             \"*_n\"
-- Clocks:                 \"clk\", \"clk*\", \"_clk\",
-- Resets:                 \"*_rst\", \"*_reset\"
-- Generics:               \"G_*\"
-- Constants:              \"C_*\"
-- User defined types:     \"*_type\", \"T_*\"  (state machine definition)
-- Inputs:                 \"*_i\"
-- Outputs:                \"*_o\"
-- Bidirectional:          \"*_io\", \"io_*\"
-- Counter Signals:        \"*_cnt\", \"counter\"
-- Combinatorial signals:  \"*_s\"
-- Asynchronous signals:   \"*_a\"
-- Shift registers:        \"*_sr\"
-- Register delay signals: \"*_d#\"
-- Clock enable signals:   \"*_ce\"
-- Processes:              \"*_PROC\"
-------------------------------------------------------------------------------
")
;;
;; Testbench settings
;;
(setopt vhdl-testbench-include-configuration nil
        vhdl-testbench-include-header t
        vhdl-testbench-include-library t
        vhdl-testbench-include-libraries '(nil t t t nil nil nil nil t))
(setopt vhdl-testbench-include-custom-library "\
use ieee.math_real.all;

library std;
use std.env.all;
use std.textio.all;

")
(setopt vhdl-testbench-declarations "\
    --
    -- Clock and Reset Declarations
    --
    signal tb_reset            : std_logic := '0';
    signal tb_clk              : std_logic := '0';
    signal tb_clk_en           : boolean   := False;
    constant C_CLK_FREQ        : real      := 100.0e6;  -- Hz
    constant C_CLK_PERIOD_REAL : real      := 1.0 / C_CLK_FREQ;
    constant C_CLK_PERIOD_TIME : time      := C_CLK_PERIOD_REAL * (1 SEC);
")
(setopt vhdl-testbench-statements "\
    ----------------------------------------------------------------------------
    -- Clocks and Resets
    ----------------------------------------------------------------------------
    TB_CLK_GEN : process
    begin
        tb_clk <= '0';
        wait for C_CLK_PERIOD_TIME / 2;
        tb_clk <= '1';
        wait for C_CLK_PERIOD_TIME / 2;
    end process TB_CLK_GEN;

    TB_RESET_GEN : process
    begin
        tb_reset <= '1', '0' after 20*C_CLK_PERIOD_TIME;
        wait;
    end process TB_RESET_GEN;

    ----------------------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------------------
    STIMULUS : process
    begin
        -- Initialization
        wait until (tb_reset = '0');

        -- Stop
        std.env.stop(0);
        wait;
    end process STIMULUS;
")

(provide 'vhdl-mode-config)
