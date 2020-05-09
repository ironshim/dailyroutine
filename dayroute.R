
library(httr)
library(rvest)
library(readr)
library(dplyr)
library(stringr)


rm(list=ls())
setwd("A:/google_drive/2020_R_investment/dailyroute")

###########down_sector#############################


# 최근 영업일 구하기
url = 'https://finance.naver.com/sise/sise_index.nhn?code=KOSPI'

biz_day = GET(url) %>%
    read_html(encoding = 'EUC-KR')%>%
    html_nodes(xpath =
                   '//*[@id="time"]') %>%
    html_text() %>%
    str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
    str_replace_all('\\.', '')

# 산업별 현황 OTP 발급
gen_otp_url =
    'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'

gen_otp_data = list(
    name = 'fileDown',
    filetype = 'csv',
    url = 'MKD/03/0303/03030103/mkd03030103',
    tp_cd = 'ALL',
    date = biz_day, # 최근영업일로 변경
    lang = 'ko',
    pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')


otp = POST(gen_otp_url, query = gen_otp_data) %>%
    read_html() %>%
    html_text()


# 산업별 현황 데이터 다운로드
down_url = 'http://file.krx.co.kr/download.jspx'
down_sector = POST(down_url, query = list(code = otp),
                   add_headers(referer = gen_otp_url)) %>%
    read_html() %>%
    html_text() %>%
    read_csv()

ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_sector, 'data/krx_sector.csv')

# 개별종목 지표 OTP 발급
gen_otp_url =
    'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
    name = 'fileDown',
    filetype = 'csv',
    url = "MKD/13/1302/13020401/mkd13020401",
    market_gubun = 'ALL',
    gubun = '1',
    schdate = biz_day, # 최근영업일로 변경
    pagePath = "/contents/MKD/13/1302/13020401/MKD13020401.jsp")

otp = POST(gen_otp_url, query = gen_otp_data) %>%
    read_html() %>%
    html_text()

# 개별종목 지표 데이터 다운로드
down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code = otp),
                add_headers(referer = gen_otp_url)) %>%
    read_html() %>%
    html_text() %>%
    read_csv()

write.csv(down_ind, 'data/krx_ind.csv')



# 5.1.4 거래소 데이터 정리하기
# 위에서 다운로드한 데이터는 중복된 열이 있으며, 불필요한 데이터 역시 있습니다. 따라서 하나의 테이블로 합친 후 정리할 필요가 있습니다. 먼저 다운로드한 csv 파일을 읽어옵니다.

down_sector = read.csv('data/krx_sector.csv', row.names = 1,
                       stringsAsFactors = FALSE)
down_ind = read.csv('data/krx_ind.csv',  row.names = 1,
                    stringsAsFactors = FALSE)

# read.csv() 함수를 이용해 csv 파일을 불러옵니다. 
# row.names = 1을 통해 첫 번째 열을 행 이름으로 지정하고, stringsAsFactors = FALSE를 통해 문자열 데이터가 팩터 형태로 변형되지 않게 합니다.

intersect(names(down_sector), names(down_ind))
# ## [1] "종목코드" "종목명"
# 먼저 intersect() 함수를 통해 두 데이터 간 중복되는 열 이름을 살펴보면 종목코드와 종목명이 동일한 위치에 있습니다.

setdiff(down_sector[, '종목명'], down_ind[ ,'종목명'])

## [37] "SNK"                "SBI핀테크솔루션즈" 
## [39] "잉글우드랩"         "코오롱티슈진"      
## [41] "엑세스바이오"
# setdiff() 함수를 통해 두 데이터에 공통적으로 없는 종목명, 즉 하나의 데이터에만 있는 종목을 살펴보면 위와 같습니다. 해당 종목들은 선박펀드, 광물펀드, 해외종목 등 일반적이지 않은 종목들이므로 제외하는 것이 좋습니다. 따라서 둘 사이에 공통적으로 존재하는 종목을 기준으로 데이터를 합쳐주겠습니다.

KOR_ticker = merge(down_sector, down_ind,
                   by = intersect(names(down_sector),
                                  names(down_ind)),
                   all = FALSE
)


KOR_ticker = KOR_ticker[order(-KOR_ticker['시가총액.원.']), ]

##      종목코드           종목명 시장구분 산업분류
## 332    005930         삼성전자   코스피 전기전자
## 45     000660       SK하이닉스   코스피 전기전자
## 333    005935       삼성전자우   코스피 전기전자
## 1938   207940 삼성바이오로직스   코스피   의약품

# 데이터를 시가총액 기준으로 내림차순 정렬할 필요도 있습니다. order() 함수를 통해 상대적인 순서를 구할 수 있습니다. R은 기본적으로 오름차순으로 순서를 구하므로 앞에 마이너스(-)를 붙여 내림차순 형태로 바꿉니다. 결과적으로 시가총액 기준 내림차 순으로 해당 데이터가 정렬됩니다.
# 
# 마지막으로 스팩, 우선주 종목 역시 제외해야 합니다.


KOR_ticker[grepl('스팩', KOR_ticker[, '종목명']), '종목명']  


##  [1] "엔에이치스팩14호"    "하나금융11호스팩"   
##  [3] "케이비제18호스팩"    "엔에이치스팩12호"   
##  [5] "삼성스팩2호"         "한화에스비아이스팩" 
##  [7] "미래에셋대우스팩3호" "신한제4호스팩"      
##  [9] "유안타제5호스팩"     "SK6호스팩"          
## [11] "케이비17호스팩"      "대신밸런스제7호스팩"

KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) != 0, '종목명']
##   [1] "삼성전자우"         "현대차2우B"        
##   [3] "LG생활건강우"       "현대차우"          


#grepl()  함수를 통해 종목명에 ‘스팩’이 들어가는 종목을 찾고, stringr 패키지의 str_sub() 함수를 통해 종목코드 끝이 0이 아닌 우선주 종목을 찾을 수 있습니다.

KOR_ticker = KOR_ticker[!grepl('스팩', KOR_ticker[, '종목명']), ]  
KOR_ticker = KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) == 0, ]
# 마지막으로 행 이름을 초기화한 후 정리된 데이터를 csv 파일로 저장합니다.

rownames(KOR_ticker) = NULL
write.csv(KOR_ticker, 'data/KOR_ticker.csv')


# 5.2 WICS 기준 섹터정보 크롤링
# 일반적으로 주식의 섹터를 나누는 기준은 MSCI와 S&P가 개발한 GICS12를 가장 많이 사용합니다. 국내 종목의 GICS 기준 정보 역시 한국거래소에서 제공하고 있으나, 이는 독점적 지적재산으로 명시했기에 사용하는 데 무리가 있습니다. 그러나 지수제공업체인 와이즈인덱스13에서는 GICS와 비슷한 WICS 산업분류를 발표하고 있습니다. WICS를 크롤링해 필요한 정보를 수집해보겠습니다.
# 
# 먼저 웹페이지에 접속해 [Index → WISE SECTOR INDEX → WICS → 에너지]를 클릭합니다. 그 후 [Components] 탭을 클릭하면 해당 섹터의 구성종목을 확인할 수 있습니다.
# 
# 
library(jsonlite)

url = 'http://www.wiseindex.com/Index/GetIndexComponets?ceil_yn=0&dt=20190607&sec_cd=G10'
data = fromJSON(url)

lapply(data, head)


sector_code = c('G25', 'G35', 'G50', 'G40', 'G10',
                'G20', 'G55', 'G30', 'G15', 'G45')
data_sector = list()

for (i in sector_code) {
    
    url = paste0(
        'http://www.wiseindex.com/Index/GetIndexComponets',
        '?ceil_yn=0&dt=20190607&sec_cd=',i)
    data = fromJSON(url)
    data = data$list
    
    data_sector[[i]] = data
    
    Sys.sleep(1)
}

data_sector = do.call(rbind, data_sector)
# 해당 데이터를 csv 파일로 저장해주도록 합니다.

write.csv(data_sector, 'data/KOR_sector.csv')


#sector finish ###############################



# 거래량 기준 급등 화면 데이터 다운로드 
gen_otp_url =
    'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
    name = 'fileDown',
    filetype = 'csv',
    url = "MKD/13/1302/13020101/mkd13020101",
    market_gubun = 'ALL',
    gubun = '1',
    schdate = biz_day, # 최근영업일로 변경,
    pagePath = "/contents/MKD/13/1302/13020101/MKD13020101.jsp")


otp = POST(gen_otp_url, query = gen_otp_data) %>%
    read_html() %>%
    html_text()


# 개별종목 지표 데이터 다운로드
down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code = otp),
                add_headers(referer = gen_otp_url)) %>%
    read_html() %>%
    html_text() %>%
    read_csv()

ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_ind, paste0('data/daily/daily_', biz_day,'.csv'))


today = down_ind[c(2,3,4,5,6,10)]
today = today[order(-today['거래량']), ]
#today = today[order(-today['등락률']), ]
today_list=filter(today, 거래량 >10000000)
today_list<-mutate(today_list, naver=종목명)
today_list<-mutate(today_list, kakao=종목명)
for(i in 1: nrow(today_list) ){
    company_name= today_list[i, '종목명']
    company_no= today_list[i, '종목코드']
    
    naverurl =paste0("https://m.stock.naver.com/item/main.nhn#/stocks/",company_no,"/total")   
    today_list[i,"naver"]=naverurl
    kakaourl =paste0("https://stockplus.onelink.me/5C89?pid=다음금융&af_dp=stockplus%3A%2F%2FviewStock?code=",company_no,"&tabIndex=0")   
    today_list[i,"kakao"]=kakaourl
}


library(dplyr)


KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_sector = read.csv('data/KOR_sector.csv', row.names = 1)



KOR_sector$'CMP_KOR' =as.character(KOR_sector$'CMP_KOR')
KOR_ticker$'종목명' =as.character(KOR_ticker$'종목명')

data_market = left_join(KOR_ticker, KOR_sector,
                        by = c('종목코드' = 'CMP_CD',
                               '종목명' = 'CMP_KOR'))

data_market$'종목코드' =
    str_pad(data_market$'종목코드', 6, side = c('left'), pad = '0')


today_market_list = left_join (today_list, data_market,
                               by = c('종목코드' = '종목코드',
                                      '종목명' = '종목명'))

write.csv(today_market_list, paste0('data/today_list_',biz_day,'.csv'))



# text파일 변환 #########################################################

today_market_list$'시장구분' <- as.character(today_market_list$'시장구분')
today_market_list$'산업분류' <- as.character(today_market_list$'산업분류')
today_market_list$SEC_NM_KOR <- as.character(today_market_list$SEC_NM_KOR)
today_market_list$'관리여부' <- as.character(today_market_list$'관리여부')


#i=1


cat(paste0(biz_day," 일자 거래량순 주식 분석"),"\n",
    paste0("[거래량순으로 정렬되었습니다.(1000만 이상)]"),"\n","\n",
    file = paste0('data/All_list_',biz_day,'.txt'),
    append = TRUE)

for(i in 1: nrow(today_market_list)){
    if(today_market_list[i, '등락률']>=15){
        cat(paste0(i,". [급등  ",today_market_list[i, '등락률'],"%]"),
            file = paste0('data/All_list_',biz_day,'.txt'),
            append = TRUE)
    }
    else if (today_market_list[i, '등락률']<15 & today_market_list[i, '등락률']>=1){
        cat(paste0(i,". [상승 ",today_market_list[i, '등락률'],"%]"),
            file = paste0('data/All_list_',biz_day,'.txt'),
            append = TRUE)
    }
    else if (today_market_list[i, '등락률']<1 & today_market_list[i, '등락률']>-1){
        cat(paste0(i,". [보합 ",today_market_list[i, '등락률'],"%]"),
            file = paste0('data/All_list_',biz_day,'.txt'),
            append = TRUE)
    }
    else {
        cat(paste0(i,". [하락 ",today_market_list[i, '등락률'],"%]"),
            file = paste0('data/All_list_',biz_day,'.txt'),
            append = TRUE)
    }
    cat(paste0( " :  ", today_market_list[i, '종목명'], "(",today_market_list[i, '종목코드'],")"),"\n",
        paste0( "거래(가격)폭등사유 : "),"\n",
        paste0( "관련주 : "),"\n",
        paste0( "시장구분 : ", today_market_list[i, '시장구분'], "(",today_market_list[i, '산업분류'],")-",
                today_market_list[i, 'SEC_NM_KOR'],"  ",today_market_list[i, '관리여부']), "\n",
        paste0( "시가총액 : ", round(today_market_list[i, '시가총액.원.']/100000000,2), "억원"),"\n",
        paste0("PER(주가수익비율): ",today_market_list[i, 'PER']," / PBR(주가순자산 비율) : ",today_market_list[i, 'PBR']),"\n",
        paste0(" / 주당 배당금 :", today_market_list[i, '주당배당금'],
               " / 배당수익율(1주) :", today_market_list[i, '배당수익률']), "\n",
        paste0("현재가 :",today_market_list[i, '현재가'],", /  등락률:  ",today_market_list[i, '등락률'], "%  / 거래량 :",
               round(today_market_list[i, '거래량']/10000),"만 회"),"\n","\n",
        paste0("네이버 금융 링크"),"\n",
        paste0(today_market_list[i, 'naver']),"\n",
        paste0("증권플러스 앱 링크"),"\n",
        paste0(today_market_list[i, 'kakao']),"\n","\n",
        file = paste0('data/All_list_',biz_day,'.txt'),
        append = TRUE)
}    




###########구글 드라이브 업로드 #############
library(googledrive)
drive_auth(email = "ryan.shim11@gmail.com")
drive_upload(paste0("A:/google_drive/2020_R_investment/dailyroute/data/All_list_",biz_day,".txt"),paste0('All_list_',biz_day,".txt"), path= "/2020_investment")


###########텔레그램 챗봇  #############

library(telegram.bot)
bot = Bot(token = '1187850055:AAGmEGzKgj56HwjGkYNkiofoaoh6FtACaLI')
updates = bot$getUpdates()
chat_id = updates[[1]]$message$chat$id

library(lubridate)

document_loc <- paste0("A:/google_drive/2020_R_investment/dailyroute/data/All_list_",biz_day,".txt")
newsdata <-read.delim(paste0('data/Top20_list_',biz_day,'.txt'), header= FALSE)
newsdata1<-paste0(" ")

newsdata1<-paste(newsdata1,as.character(newsdata[1,1]),sep="\n")
sapply(newsdata1, function(x) {bot$sendMessage(chat_id = chat_id, x)})

for(i in 0: 1){
    for( k in  (12*i+3) : (12*i+13)){
        newsdata1<-paste(newsdata1,as.character(newsdata[k,1]),sep="\n")
    }
    sapply(newsdata1, function(x) {bot$sendMessage(chat_id = chat_id, x)})
    newsdata1<-paste0(" ")
    Sys.sleep(5)
}

bot$sendDocument(
    chat_id = chat_id,
    document = document_loc
)

