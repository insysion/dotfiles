import Data.List (isPrefixOf, isSuffixOf)
import Data.Map (union, fromList)
import XMonad
import XMonad.Actions.DynamicWorkspaces (removeWorkspace, renameWorkspace)
import XMonad.Actions.DynamicWorkspaces (appendWorkspacePrompt, withNthWorkspace)
import XMonad.Config.Kde (desktopLayoutModifiers, kde4Config)
import XMonad.Hooks.EwmhDesktops (ewmh, fullscreenEventHook)
import XMonad.Hooks.InsertPosition (insertPosition)
import XMonad.Hooks.InsertPosition (Focus (Newer), Position (Below))
import XMonad.Hooks.ManageHelpers (doFullFloat, isFullscreen)
import XMonad.Hooks.Minimize (minimizeEventHook)
import XMonad.Layout.GridVariants
import XMonad.Layout.Minimize (minimize, minimizeWindow)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerScreen (ifWider)
import XMonad.Layout.Spacing (spacingWithEdge)
import XMonad.Layout.ThreeColumns (ThreeCol (ThreeColMid))
import qualified XMonad.StackSet as W

main =
  xmonad $ ewmh $
    kde4Config
      { modMask = mod4Mask
      , manageHook = manageHook kde4Config <+> myManageHook
      , layoutHook = myLayoutHook
      , keys = \c -> myKeys c `union` keys kde4Config c
      , handleEventHook = handleEventHook kde4Config <+> myHandleEventHook
      , mouseBindings = \w -> myMouse w `union` mouseBindings kde4Config w
      , workspaces = [ "General" ]
      }

myKeys (XConfig {modMask = modm}) =
  fromList $
    [ ( (modm,               xK_m),      withFocused minimizeWindow)
    , ( (modm,               xK_F11),    withFocused fullFloat)
    , ( (modm,               xK_equal),  renameWorkspace def)
    , ( (modm .|. shiftMask, xK_Delete), removeWorkspace)
    , ( (modm .|. shiftMask, xK_equal),  appendWorkspacePrompt def)
    ]
    ++ zip (zip (repeat (modm)) [xK_1..xK_9]) (map (withNthWorkspace W.greedyView) [0..])
    ++ zip (zip (repeat (modm .|. shiftMask)) [xK_1..xK_9]) (map (withNthWorkspace W.shift) [0..])
  where
    fullFloat w = let r = W.RationalRect 0 0 1 1
      in windows $ W.float w r 

myMouse (XConfig {modMask = modMask}) =
  fromList $
    [ ( (modMask .|. shiftMask, button1), \w -> focus w >> kill)
    , ( (modMask , button4), \w -> focus w >> kill)
    ]

myManageHook =
  composeAll . concat $
    [ [isFullscreen --> doFullFloat]
    , [fmap (t `isSuffixOf`) title --> doFullFloat | t <- myTitleSuffixFullFloats]
    , [title =? t --> doFloat                      | t <- myTitleFloats]
    , [className =? c --> doFloat                  | c <- myClassFloats]
    , [className =? c --> insertNewerBelow         | c <- myClassBelows]
    , [ (className =? "jetbrains-pycharm-ce" <&&> fmap (t `isPrefixOf`) title)
          --> insertNewerBelow                     | t <- pycharmBelows
      ]
    , [ (className =? "jetbrains-pycharm-ce" <&&> title =? t)
          --> unFloat                              | t <- pycharmUnfloats
      ]
    , [ (className =? "zoom" <&&> fmap (t `isPrefixOf`) title)
          --> insertNewerBelow                     | t <- zoomBelows
      ]
    ]
  where
    insertNewerBelow = insertPosition Below Newer
    myClassFloats =
      [ "MPlayer"
      , "Gimp"
      , "plasmashell"
      , "Plasma"
      , "krunner"
      , "Kmix"
      , "Klipper"
      , "Plasmoidviewer"
      , "xmessage"
      ]
    myTitleFloats =
      [ "alsamixer"
      , "plasma-desktop"
      , "win7"
      , "Choose Files"
      , "Authy"
      , "StayFocusd"
      ]
    pycharmBelows =
      [ "Run"
      , "Debug"
      , "Terminal"
      , " "
      , "Breakpoints"
      , "Find"
      , "Version Control"
      , "Project"
      ]  
    zoomBelows =
      [ "Chat"
      , "Participants"
      ]
    myClassBelows = ["konsole"]
    pycharmUnfloats = [" ", "Breakpoints"]
    myTitleSuffixFullFloats = ["Perforce Helix Merge"]
    unFloat = ask >>= doF . W.sink

myLayoutHook =
  smartBorders
    $ desktopLayoutModifiers
    $ minimize
    $ spacingWithEdge 5
    $ myLayouts
  where
    myLayouts = TallGrid nmasterRows nmasterCols (12/21) 1.1 (4/21)
      ||| ThreeColMid nmaster (1/12) (8/21)
    nmaster = 1
    nmasterCols = 1
    nmasterRows = 1

myHandleEventHook = fullscreenEventHook <+> minimizeEventHook
