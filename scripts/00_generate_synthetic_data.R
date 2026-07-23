source("R/config.R", encoding = "UTF-8")
source("R/data_access.R", encoding = "UTF-8")
source("R/synthetic_data.R", encoding = "UTF-8")

config <- churn_config()
synthetic_data <- generate_synthetic_vehicle_months(seed = config$seed)
write_synthetic_vehicle_month_csv(synthetic_data, config$data_path)

message(
  sprintf(
    "Synthetic vehicle-month data written: %s rows -> %s",
    format(nrow(synthetic_data), big.mark = ","),
    config$data_path
  )
)
