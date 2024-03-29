#!/usr/bin/env hy3

(import argparse
        curses
        [itertools [count]]
        [pathlib [Path]])

(defn lines-from [filename]
  (with [f (open filename)]
    (setv out {})
    (for [[l i] (zip f (count))]
      (assoc out i l))
    (return out)))

(defn run [filename initial-line margin screen]
  (setv lines (lines-from filename))
  (setv current-line initial-line)
  (setv w curses.COLS)
  (setv h (dec curses.LINES))

  (while True
    (screen.clear)
    (for [i (range h)]
      (screen.addstr i margin (.get lines (+ current-line i) "")))
    (for [i (range h)]
      (screen.addstr i (+ (int (/ w 2)) margin) (.get lines (+ current-line i h) "")))
    (screen.refresh)

    (try
      (setv key (screen.getkey))
      (except [Exception]
        (continue)))

    (cond
      [(= key "q") (break)]
      [(= key "KEY_UP") (setv current-line (dec current-line))]
      [(= key "KEY_DOWN") (setv current-line (inc current-line))]
      [(= key " ") (setv current-line (+ current-line h))]))

  (return current-line))

(defmain [&rest _]
  (setv parser (argparse.ArgumentParser))
  (.add-argument parser "-file" :type string :default None
    :help "File to read")
  (.add-argument parser "-line" :type int :default 0
    :help "Start reading from a specific line")
  (.add-argument parser "-margin" :type int :default 0
    :help "Padding to add to the left side of the text.")
  (.add-argument parser "--resume" :dest "resume" :action "store_const"
    :const True :default False
    :help "Resume reading your last file where you left off.")
  (setv args (parser.parse-args))

  (unless (or args.file args.resume)
    (print "Give me a file to read.")
    (return))

  (if args.resume
    (do
      (with [f (open (/ (Path.home) ".split-resume"))]
        (setv file (.strip (f.readline)))
        (setv line (int (.strip (f.readline))))
        (setv last-line (curses.wrapper (fn [screen] (run file line args.margin screen))))))
    (setv last-line (curses.wrapper (fn [screen] (run args.file args.line args.margin screen)))))

  (print "You finished on line:" last-line)

  (with [f (open (/ (Path.home) ".split-resume") "w")]
    (print (if args.file
               (str (/ (Path.cwd) args.file))
               file) :file f)
    (print (str last-line) :file f)))
