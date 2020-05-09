

#태스크 스케줄러 

library(taskscheduleR)
setwd("A:/google_drive/2020_R_investment/dailyroute")
dayroute.schedule = file.path('A:/google_drive/2020_R_investment/dailyroute/telegram.R')

## 지금으로 부터 10초 뒤 실행하고 10분 마다 재 실행
taskscheduler_create(taskname = 'Telegram', rscript = dayroute.schedule,
                     schedule = 'DAILY',
                     starttime = "15:48",
                     startdate = format(Sys.time(), '%Y/%m/%d'))
 

`#taskscheduler_delete('save data') # 스케쥴 삭제



#태스크 스케줄러 

library(taskscheduleR)
setwd("A:/Dropbox/_individual project/2020_R_investment/dailyroute")
dayroute.schedule = file.path('A:/Dropbox/_individual project/2020_R_investment/dailyroute/dayroute.R')

## 지금으로 부터 10초 뒤 실행하고 10분 마다 재 실행
taskscheduler_create(taskname = 'daily route_save data', rscript = dayroute.schedule,
                     schedule = 'DAILY',
                     starttime = "15:30",
                     startdate = format(Sys.time(), '%Y/%m/%d'))


`#taskscheduler_delete('save data') # 스케쥴 삭제
