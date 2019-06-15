{-# LANGUAGE OverloadedStrings
  , BangPatterns
  , MultiWayIf
  , LambdaCase
  , TemplateHaskell
#-}
module Main where


import           Control.Monad                  ( void )

import qualified Graphics.UI.FLTK.LowLevel.FL  as FL
import           Graphics.UI.FLTK.LowLevel.Fl_Types
import           Graphics.UI.FLTK.LowLevel.FLTKHS
                                               as FL
import           Graphics.UI.FLTK.LowLevel.Fl_Enumerations

import           Data.Vector                    ( Vector )
import qualified Data.Vector                   as V
import           Data.IORef
import           Data.Time.LocalTime
import           Data.Time.Calendar

import           Control.Lens

import           Graphics.Rendering.Chart.Easy as Ch
import           Graphics.Rendering.Chart.Backend.FLTKHS
import           Graphics.Rendering.Chart.Backend
                                               as CB

import           Prices                         ( prices
                                                , mkDate
                                                , filterPrices
                                                )

prices' :: [(LocalTime, Double, Double)]
prices' = filterPrices prices (mkDate 1 1 2005) (mkDate 31 12 2006)


chart = toRenderable layout
  where

    price1 =
        plot_lines_style
            .  line_color
            .~ opaque blue
            $  plot_lines_values
            .~ [[ (d, v) | (d, v, _) <- prices' ]]
            $  plot_lines_title
            .~ "price 1"
            $  def

    price2 =
        plot_lines_style
            .  line_color
            .~ opaque green
            $  plot_lines_values
            .~ [[ (d, v) | (d, _, v) <- prices' ]]
            $  plot_lines_title
            .~ "price 2"
            $  def

    layout =
        layoutlr_title
            .~ "Price History"
            $  layoutlr_left_axis
            .  laxis_override
            .~ axisGridHide
            $  layoutlr_right_axis
            .  laxis_override
            .~ axisGridHide
            $  layoutlr_x_axis
            .  laxis_override
            .~ axisGridHide
            $  layoutlr_plots
            .~ [Left (toPlot price1), Right (toPlot price2)]
            $  layoutlr_grid_last
            .~ False
            $  def



drawScene :: SceneStateRef -> Ref Widget -> IO ()
drawScene ref widget = do
    rectangle' <- getRectangle widget
    let coords@(x', y', w', h') = fromRectangle rectangle'
    withFlClip rectangle' $ do
        renderToWidgetEC widget $ do
            layoutlr_title .= "Price History"
            layoutlr_left_axis . laxis_override .= axisGridHide
            layoutlr_right_axis . laxis_override .= axisGridHide
            plotLeft (line "price 1" [[ (d, v) | (d, v, _) <- prices' ]])
            plotRight (line "price 2" [[ (d, v) | (d, _, v) <- prices' ]])




data SceneState = SceneState {
    scWidth :: Width
    , scHeight :: Height
    , scTheta :: Double
    }


type SceneStateRef = IORef SceneState


main :: IO ()
main = do
    let width  = 800
        height = 600
        fAspectRatio :: Double
        fAspectRatio = fromIntegral height / fromIntegral width

    ref     <- newIORef (SceneState (Width width) (Height height) 0.0)

    window' <- doubleWindowNew (Size (Width width) (Height height))
                               Nothing
                               Nothing
    begin window'
    widget' <- widgetCustom
        (FL.Rectangle (Position (X 0) (Y 0))
                      (Size (Width width) (Height height))
        )
        Nothing
        (drawScene ref)
        defaultCustomWidgetFuncs
    end window'
    showWidget window'
    void FL.run

