.libPaths(c("C:/R/R-3.6.3/library", .libPaths()))

library(httr)
library(rvest)
library(readr)
library(dplyr)
library(stringr)
library(telegram.bot)



bot = Bot(token = '1187850055:AAGmEGzKgj56HwjGkYNkiofoaoh6FtACaLI')
print(bot$getMe())
updates = bot$getUpdates()
chat_id = updates[[1]]$message$chat$id




# 최근 영업일 구하기
url = 'https://finance.naver.com/sise/sise_index.nhn?code=KOSPI'

biz_day = GET(url) %>%
    read_html(encoding = 'EUC-KR')%>%
    html_nodes(xpath =
                   '//*[@id="time"]') %>%
    html_text() %>%
    str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
    str_replace_all('\\.', '')


document_loc <- paste0("A:/google_drive/2020_R_investment/dailyroute/data/All_list_",biz_day,".txt")

bot$sendMessage(chat_id = chat_id, text = '오늘의 거래량 분석이 도착했습니다.')

bot$sendDocument(
    chat_id = chat_id,
    document = document_loc
)

