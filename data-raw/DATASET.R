## code to prepare `DATASET` dataset goes here

# Creates age.groups list
age.groups <- list(
  ILI    = c(0,5,25,50,65, Inf),
  IMM    = c(0,1,5,10,15,20,30,40,50,60, Inf),
  Yr.5   = c(seq(from = 0,to = 70,by=5), Inf),
  Yr.10  = c(seq(from = 0, to = 70, by =10), Inf ),
  Spec   = c(0,1,5,10,20,40,60, Inf),
  Annual = c(0,15,25,45,65, Inf),
  School = c(0,5,11,14,19,24,seq(from = 30, to = 70, by = 10), Inf),
  Covid  = c(0,5,12,18, 20,30,40,50, 60, 70, Inf)
)

usethis::use_data(age.groups, overwrite = TRUE)
