module Main exposing (main)

import Browser
import Page as Page

main = Browser.element
    { init = Page.init
    , update = Page.update
    , view = Page.view
    , subscriptions = Page.subscriptions
    }
