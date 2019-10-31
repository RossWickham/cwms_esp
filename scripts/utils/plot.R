
# forming colors for given set of inputs
getColor <- function(yr,allYrs){
  #Getting the full pallette
  pal <- RColorBrewer::brewer.pal(length(allYrs),"Set1")
  pal[which(allYrs==yr)]
}


createVerticalPlotly <- function(config, espData, espQData, metrics, selectedYrs, selectedFcstInfo){
  #All data on one huge subplot
  require(plotly)
  require(dplyr)
  plotConfig <- bind_rows(config)
  p <- list()
  init <- F #indicates whether or not plot has been initialized
  
  #Line indicating when the forecast starts
  #yref = "paper" allow you to specify a position that is always relative to the plot,
  #  y=1 refers to the top of plot and y=0 refers to the bottom of the plot:
  #  https://stackoverflow.com/questions/41267246/how-to-add-annotations-horizontal-or-vertical-reference-line-in-plotly
  fcstStartData <- selectedFcstInfo$fcstTime
  fcstStartAnnotation <- list(yref = 'paper', xref = "x", y = 0.5, x = fcstStartData, opacity=0.5,
                              text = "Forecast Start",textangle=-90,showarrow=F)
  
  for(k in 1:nrow(plotConfig)){
    
    #extracting plot parameters to simplify eval (had difficulty wrapping plot_ly in with statement)
    sqlite_tblname <- plotConfig$sqlite_tblname[k]
    yaxis_label <- plotConfig$yaxis_label[k]
    
    #extracting ESP lines and quantiles
    plotData <- espData[[sqlite_tblname]]
    qData <- espQData[[sqlite_tblname]]


    p[[k]] <-plot_ly(plotData, x=~date, y=~value,color=~year,
                     type = "scatter",mode="lines",
                     hoverinfo="x+y+text",
                     text=~paste0(year),
                     showlegend=F,name="",legendgroup="allESP",
                     line=list(color=colToHex("grey",0.4))) %>%
      layout(xaxis=list(title=""),yaxis=list(title=yaxis_label))
      # layout(xaxis=list(title=""),yaxis=list(title=yaxis_label),annotations=list(fcstStartAnnotation))

    #dummy to control all ESP
    p[[k]] <-p[[k]]  %>% add_trace(data = plotData[1,], x=~date, y=~value,color=~year,
                                   type = "scatter",mode="lines",
                                   line=list(color=colToHex("grey",0.4)),
                                   showlegend=!init,name="All ESP",legendgroup="allESP",
                                   inherit=F)
    
    
    # Adding metrics if any current selected
    if( length(metrics) != 0){
      for( metric in metrics){
        lineData <- qData[, c("date",metric)]
        names(lineData) <- c("date", "value")
        #The line type, as specified in the global.R script
        lty_plotly <- metricsToCompute$lty_plotly[metricsToCompute$metric==metric]
        
        p[[k]] <- p[[k]] %>% 
          add_trace(data = lineData,x=~date, y=~value,
                    type = "scatter",mode="lines",
                    line=list(dash=lty_plotly,color=colToHex("black",0.7)), name=metric,
                    legendgroup=metric, showlegend=!init,inherit = F)
      }
    }
    
    #Adding selected ESP years
    if( length(selectedYrs) != 0){
      
      if(length(selectedYrs) > 9)
        cat("\n\tCan only plot up to 9 ESP years at once and preserve color scheme.\n\tPlease reduce number of selected years.")
      
    
      for( selectedYr in selectedYrs){
        lineData <- plotData[plotData$year == selectedYr, c("date","value")]

        p[[k]] <- p[[k]] %>% 
          add_trace(data = lineData,x=~date, y=~value,
                    line=list(color=getColor(selectedYr,selectedYrs)),
                    type = "scatter",mode="lines",name=selectedYr,
                    legendgroup=selectedYr, showlegend=!init,inherit = F)
      }
    }

    init <- T
  }
  return(subplot(p,nrows = length(p), shareX = T, titleY = T, widths = 1))
}
