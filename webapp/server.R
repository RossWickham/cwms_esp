#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#



shinyServer(function(input, output) {
   

  output$current_data_tbl <-
    # renderUI({ tags$div( c(cwmsDataString),tags$br) ) })
    renderUI({
      HTML( paste(getCurrentCWMSTableStrings(cDataTbl), collapse="<br/>") )
      })
  
  output$fcstNote <- renderUI({
    HTML("Note: Data will update once CWMS<br/>forecast is within forecast time window<br/>")})
  
  
  getFcstInfo <- eventReactive(c(input$selectedFcst),{
    # getVerticalPlotly<- eventReactive(c(input$selectedFcst, input$metrics),{
    require(plotly)
    selectedFcstInfo <- fcstInfo[[input$selectedFcst]]
    HTML(sprintf(paste0(
      "Watershed:             %s<br/>",
      "Forecast Name          %s<br/>",
      "Start Time:            %s<br/>",
      "Forecast Start Time:   %s<br/>",
      "End Time:              %s"),
      selectedFcstInfo$watershed,
      selectedFcstInfo$description,
      selectedFcstInfo$startTime,
      selectedFcstInfo$fcstTime,
      selectedFcstInfo$endTime))
  })
  
  output$fcst_info <- renderUI(getFcstInfo())
  
  getVerticalPlotly<- eventReactive(c(input$updateButton),{
  # getVerticalPlotly<- eventReactive(c(input$selectedFcst, input$metrics),{
    require(plotly)
    espData <- allESPData[[input$selectedFcst]]
    espQData <- allQuantileData[[input$selectedFcst]]
    createVerticalPlotly(config,espData, espQData, input$metrics, input$selectedYrs, fcstInfo[[input$selectedFcst]])
  })
  
  output$bigPlot <- renderPlotly(getVerticalPlotly())
  

  getFcstTbl<- eventReactive(c(input$selectedFcst),{
    #grab the correct, pre-computed table from list
    fcstDataTbl[[input$selectedFcst]]
  })
  
  if(nrow(fcstTbl)==1){
    output$fcst_table <- renderDataTable({getFcstTbl()},
                                         options=list(pageLength = length(availableYrs)))
  }else{
    output$fcst_table <- NA
  }

  
  # savePDFPlot <- eventReactive(c(input$savePDFButton),{
  #   #Saves to PDF
  #   espData <- allESPData[[input$selectedFcst]]
  #   espQData <- allQuantileData[[input$selectedFcst]]
  #   saveToPdf(config,espData, espQData, input$metrics, input$selectedYrs, fcstInfo[[input$selectedFcst]])
  # })
  
  observeEvent(input$savePDFButton,{
    #Saves to PDF
    espData <- allESPData[[input$selectedFcst]]
    espQData <- allQuantileData[[input$selectedFcst]]
    saveToPdf(config,espData, espQData, input$metrics, input$selectedYrs, fcstInfo[[input$selectedFcst]])
  })
  # renderUI(savePDFPlot())
  
  # output$savePDFPlot <- downloadHandler(filename = "foo.pdf",
                                        # content = savePDFPlot())
})
