# Sales Rep Performance Dashboard
#
# Interactive Shiny dashboard for exploring rep performance scores.
# Allows CSV upload, weight adjustment, filtering, and score export.
# Single-file app — no modules needed yet (defer until complexity requires it).

# Prevent shinytest2/Shiny from autoloading R/ files when running in a
# package directory (we source explicitly below)
options(shiny.autoload.r = FALSE)

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(plotly)
library(ggplot2)

# Source all required functions
source(file.path("R", "shiny_helpers.R"))
source(file.path("R", "scoring_utils.R"))
source(file.path("R", "normalization.R"))
source(file.path("R", "dimension_scoring.R"))
source(file.path("R", "calculate_scores.R"))

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Sales Rep Performance"),

  dashboardSidebar(
    sidebarMenu(
      id = "sidebar_menu",
      menuItem("Rankings", tabName = "rankings", icon = icon("table")),
      menuItem("Trends", tabName = "trends", icon = icon("line-chart")),
      menuItem("Upload Data", tabName = "upload", icon = icon("upload"))
    ),

    hr(),
    h4("Weight Configuration", style = "padding-left: 15px;"),
    sliderInput("weight_activity", "Activity Quality",
                min = 0, max = 1, value = 0.333, step = 0.01),
    sliderInput("weight_conversion", "Conversion Efficiency",
                min = 0, max = 1, value = 0.334, step = 0.01),
    sliderInput("weight_revenue", "Revenue Contribution",
                min = 0, max = 1, value = 0.333, step = 0.01),

    hr(),
    h4("Filters", style = "padding-left: 15px;"),
    selectInput("filter_rep", "Filter by Rep:",
                choices = NULL,
                selected = NULL,
                multiple = FALSE),
    selectInput("filter_period", "Filter by Period:",
                choices = NULL,
                selected = NULL,
                multiple = FALSE),
    actionButton("clear_filters", "Clear Filters", icon = icon("times")),

    hr(),
    checkboxInput("debug_mode", "Debug Mode: Show Intermediate Columns",
                  value = FALSE)
  ),

  dashboardBody(
    tabItems(
      # Rankings tab
      tabItem(
        tabName = "rankings",
        fluidRow(
          box(
            title = "Export Data", width = 12,
            downloadButton("export_csv", "Export Scored Data (CSV)",
                           icon = icon("download")),
            helpText("Downloads currently displayed data",
                     "(respects active filters and debug mode)")
          )
        ),
        fluidRow(
          box(
            title = "Rep Rankings", width = 12, status = "primary",
            textOutput("data_summary"),
            hr(),
            DTOutput("rankings_table")
          )
        ),
        fluidRow(
          box(
            title = "Dimension Breakdown (Top 10 Reps)", width = 12,
            status = "info",
            plotlyOutput("dimension_chart", height = "400px")
          )
        )
      ),

      # Trends tab
      tabItem(
        tabName = "trends",
        fluidRow(
          box(
            title = "Select Reps to Compare", width = 4,
            uiOutput("rep_selector")
          ),
          box(
            title = "Score Trend Over Time", width = 8, status = "info",
            plotlyOutput("trend_chart", height = "400px")
          )
        )
      ),

      # Upload tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "Upload Sales Data", width = 6,
            p("Upload a CSV file with the same schema as sample_reps.csv:"),
            tags$ul(
              tags$li("rep_id, rep_name, tenure_months, calls_made,",
                      "followups_done"),
              tags$li("meetings_scheduled, deals_closed,",
                      "revenue_generated"),
              tags$li("quota, territory_size, period")
            ),
            fileInput("file_upload", "Choose CSV File",
                      accept = c("text/csv", ".csv")),
            actionButton("load_sample", "Load Sample Data",
                         icon = icon("refresh")),
            hr(),
            verbatimTextOutput("upload_status")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {

  # Reactive: Load raw data (default to sample_reps.csv)
  raw_data <- reactiveVal(
    read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
  )

  # Reactive: Normalized weights for scoring
  # Sliders auto-adjust to sum to 1.0 via the observer below.
  # This reactive reads slider values and normalizes for calculate_scores().
  normalized_weights <- reactive({
    normalize_three_weights(
      input$weight_activity,
      input$weight_conversion,
      input$weight_revenue
    )
  })

  # Track previous slider values to detect which slider the user changed.
  # When one slider changes, the other two adjust proportionally to maintain
  # sum = 1.0. Uses freezeReactiveValue to prevent infinite reactive loops.
  prev_slider <- list(activity = 0.333, conversion = 0.334, revenue = 0.333)

  observe({
    w_a <- input$weight_activity
    w_c <- input$weight_conversion
    w_r <- input$weight_revenue

    total <- w_a + w_c + w_r

    # Already normalized — update tracking and return
    if (abs(total - 1.0) < 0.01) {
      prev_slider$activity <<- w_a
      prev_slider$conversion <<- w_c
      prev_slider$revenue <<- w_r
      return()
    }

    # Detect which slider changed by comparing to previous values
    changed <- NULL
    if (abs(w_a - prev_slider$activity) > 0.005) changed <- "activity"
    else if (abs(w_c - prev_slider$conversion) > 0.005) changed <- "conversion"
    else if (abs(w_r - prev_slider$revenue) > 0.005) changed <- "revenue"

    if (is.null(changed)) return()

    # Keep the changed slider fixed, redistribute remaining to other two
    if (changed == "activity") {
      remaining <- max(0, 1.0 - w_a)
      other_total <- w_c + w_r
      if (other_total > 0) {
        new_c <- remaining * (w_c / other_total)
        new_r <- remaining - new_c
      } else {
        new_c <- remaining / 2
        new_r <- remaining / 2
      }
      new_a <- w_a
    } else if (changed == "conversion") {
      remaining <- max(0, 1.0 - w_c)
      other_total <- w_a + w_r
      if (other_total > 0) {
        new_a <- remaining * (w_a / other_total)
        new_r <- remaining - new_a
      } else {
        new_a <- remaining / 2
        new_r <- remaining / 2
      }
      new_c <- w_c
    } else {
      remaining <- max(0, 1.0 - w_r)
      other_total <- w_a + w_c
      if (other_total > 0) {
        new_a <- remaining * (w_a / other_total)
        new_c <- remaining - new_a
      } else {
        new_a <- remaining / 2
        new_c <- remaining / 2
      }
      new_r <- w_r
    }

    # Round to slider precision
    new_a <- round(new_a, 2)
    new_c <- round(new_c, 2)
    new_r <- round(new_r, 2)

    # Update tracking before updating sliders
    prev_slider$activity <<- new_a
    prev_slider$conversion <<- new_c
    prev_slider$revenue <<- new_r

    # Freeze all inputs to prevent re-triggering this observer
    freezeReactiveValue(input, "weight_activity")
    freezeReactiveValue(input, "weight_conversion")
    freezeReactiveValue(input, "weight_revenue")
    updateSliderInput(session, "weight_activity", value = new_a)
    updateSliderInput(session, "weight_conversion", value = new_c)
    updateSliderInput(session, "weight_revenue", value = new_r)
  })

  # Observer: Warn if all weights are zero
  observe({
    if (input$weight_activity == 0 &&
        input$weight_conversion == 0 &&
        input$weight_revenue == 0) {
      showNotification(
        "All weights are zero. Using default equal weights (33.3% each).",
        type = "warning",
        duration = 5
      )
    }
  })

  # Reactive: Scored data with performance monitoring
  scored_data <- reactive({
    req(raw_data())

    start_time <- Sys.time()

    result <- calculate_scores(
      raw_data(),
      weights = normalized_weights(),
      debug = input$debug_mode
    )

    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    message("Scoring took ", round(elapsed, 3), " seconds for ",
            nrow(raw_data()), " rows")

    if (elapsed > 0.5) {
      showNotification(
        paste0("Large dataset detected \u2014 scoring took ",
               round(elapsed, 2), " seconds"),
        type = "warning",
        duration = 5
      )
    }

    result
  })

  # Reactive: List of unique reps for selectors
  available_reps <- reactive({
    scored_data() |>
      dplyr::distinct(rep_id, rep_name) |>
      dplyr::arrange(rep_name)
  })

  # Observer: Update rep filter choices when data changes
  observe({
    reps <- available_reps()
    choices <- c("All", setNames(reps$rep_id, reps$rep_name))
    updateSelectInput(session, "filter_rep",
                      choices = choices,
                      selected = "All")
  })

  # Observer: Update period filter choices when data changes
  observe({
    periods <- scored_data() |>
      dplyr::distinct(period) |>
      dplyr::pull(period) |>
      sort()

    choices <- c("All", periods)
    updateSelectInput(session, "filter_period",
                      choices = choices,
                      selected = "All")
  })

  # Observer: Clear filters button
  observeEvent(input$clear_filters, {
    updateSelectInput(session, "filter_rep", selected = "All")
    updateSelectInput(session, "filter_period", selected = "All")
  })

  # Reactive: Apply filters to scored data
  filtered_data <- reactive({
    data <- scored_data()

    if (!is.null(input$filter_rep) && input$filter_rep != "All") {
      data <- data |> dplyr::filter(rep_id == input$filter_rep)
    }

    if (!is.null(input$filter_period) && input$filter_period != "All") {
      data <- data |> dplyr::filter(period == input$filter_period)
    }

    data
  })

  # Reactive: Top 10 reps by overall score (from filtered data)
  top_reps <- reactive({
    filtered_data() |>
      dplyr::arrange(desc(score)) |>
      dplyr::slice_head(n = 10)
  })

  # Observer: Handle file upload
  observeEvent(input$file_upload, {
    req(input$file_upload)

    tryCatch({
      uploaded <- read.csv(input$file_upload$datapath,
                           stringsAsFactors = FALSE)
      validation <- validate_upload_schema(uploaded)

      if (!validation$valid) {
        output$upload_status <- renderText({
          paste("ERROR:", validation$message)
        })
      } else {
        raw_data(uploaded)
        output$upload_status <- renderText({
          paste("SUCCESS:", format_row_summary(uploaded))
        })
      }
    }, error = function(e) {
      output$upload_status <- renderText({
        paste("ERROR: Could not read file -", e$message)
      })
    })
  })

  # Observer: Load sample data button
  observeEvent(input$load_sample, {
    sample_data <- read.csv("data/sample_reps.csv", stringsAsFactors = FALSE)
    raw_data(sample_data)
    output$upload_status <- renderText({
      paste("Loaded sample data:", format_row_summary(sample_data))
    })
  })

  # Output: Data summary with score range
  output$data_summary <- renderText({
    data <- filtered_data()
    if (nrow(data) == 0) {
      return("No data matches current filters")
    }
    summary_text <- format_row_summary(data)
    score_range <- paste0(" | Scores: ",
                          round(min(data$score), 1), "-",
                          round(max(data$score), 1))
    paste0(summary_text, score_range)
  })

  # Output: Rankings table with scores
  output$rankings_table <- renderDT({
    data <- filtered_data()

    if (nrow(data) == 0) {
      return(datatable(
        data.frame(Message = "No data matches current filters"),
        options = list(dom = "t"),
        rownames = FALSE
      ))
    }

    # Sort by overall score descending
    data <- data |> dplyr::arrange(desc(score))

    # Round score columns for display
    score_cols <- c("activity_score", "conversion_score",
                    "revenue_score", "score")

    datatable(
      data,
      options = list(
        pageLength = 25,
        scrollX = TRUE
      ),
      rownames = FALSE
    ) |>
      formatRound(columns = score_cols, digits = 1) |>
      formatStyle(
        "score",
        backgroundColor = styleInterval(
          c(50, 75),
          c("#ffcccc", "#ffffcc", "#ccffcc")
        )
      )
  })

  # Output: Dimension breakdown bar chart (plotly for hover tooltips)
  output$dimension_chart <- renderPlotly({
    data <- top_reps()

    if (nrow(data) == 0) {
      p <- ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5, label = "No data to display") +
        ggplot2::theme_void()
      return(ggplotly(p))
    }

    # Create label combining rep_id, name, and period for readability
    data <- data |>
      dplyr::mutate(label = paste0(rep_id, " ", period))

    # Reshape for grouped bar chart
    chart_data <- data.frame(
      label = rep(data$label, 3),
      dimension = factor(
        rep(c("Activity", "Conversion", "Revenue"), each = nrow(data)),
        levels = c("Activity", "Conversion", "Revenue")
      ),
      score = c(data$activity_score, data$conversion_score,
                data$revenue_score)
    )

    # Preserve order (by overall score desc), use unique levels
    chart_data$label <- factor(chart_data$label,
                               levels = unique(data$label))

    plot_ly(
      chart_data,
      x = ~label, y = ~score, color = ~dimension,
      type = "bar",
      colors = c("#1f77b4", "#ff7f0e", "#2ca02c"),
      hovertemplate = paste0(
        "<b>%{x}</b><br>",
        "%{fullData.name}: %{y:.1f}<br>",
        "<extra></extra>"
      )
    ) |>
      layout(
        barmode = "group",
        xaxis = list(title = "Rep", tickangle = -45),
        yaxis = list(title = "Score (0-100)", range = c(0, 100)),
        legend = list(title = list(text = "Dimension"))
      )
  })

  # Output: Rep selector checkboxes for trend chart
  output$rep_selector <- renderUI({
    reps <- available_reps()

    checkboxGroupInput(
      "selected_reps", "Select Reps (1-5):",
      choices = setNames(reps$rep_id, reps$rep_name),
      selected = reps$rep_id[1:min(3, nrow(reps))]
    )
  })

  # Output: Trend line chart
  output$trend_chart <- renderPlotly({
    req(input$selected_reps)

    # Limit to 5 reps for readability
    selected <- input$selected_reps[1:min(5, length(input$selected_reps))]

    data <- scored_data() |>
      dplyr::filter(rep_id %in% selected) |>
      dplyr::arrange(period)

    if (nrow(data) == 0) {
      p <- ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5,
                          label = "No data for selected reps") +
        ggplot2::theme_void()
      return(ggplotly(p))
    }

    plot_ly(
      data,
      x = ~period, y = ~score, color = ~rep_name,
      type = "scatter", mode = "lines+markers",
      hovertemplate = paste0(
        "<b>%{fullData.name}</b><br>",
        "Period: %{x}<br>",
        "Score: %{y:.1f}<br>",
        "<extra></extra>"
      )
    ) |>
      layout(
        xaxis = list(title = "Period"),
        yaxis = list(title = "Score (0-100)", range = c(0, 100)),
        legend = list(title = list(text = "Rep"))
      )
  })

  # Download handler: Export scored data as CSV
  output$export_csv <- downloadHandler(
    filename = function() {
      timestamp <- format(Sys.Date(), "%Y-%m-%d")
      paste0("scored_reps_", timestamp, ".csv")
    },
    content = function(file) {
      data <- filtered_data()
      write.csv(data, file, row.names = FALSE)
    }
  )
}

# Run App
shinyApp(ui, server)
