#table one 

final <- read_rds("~/Dropbox/Mystery shopper/Data/table_one_data.rds")
colnames(final)


####################################################################################
# arsenal table one

library(arsenal)
require(knitr)
require(survival)

final <- final %>% filter(Exclusions == "Included for Analysis")
dim(final)  ##look at how many subjects and variables are in the dataset 
# help(mockstudy) ##learn more about the dataset and variables
str(final) ##quick look at the data
colnames(final)
#attr(mockstudy$sex,'label')  <- 'Gender'

mycontrols  <- tableby.control(test=FALSE, total=FALSE,
                               numeric.test="kwt", cat.test="chisq",
                               numeric.stats=c("N", "meansd"),
                               cat.stats=c("countpct"),
                               stats.labels=list(meansd='Mean, Standard Deviation', N="n"),
                               digits=1, digits.p=2, digits.pct=1)

tab1 <- tableby( ~ `Business Days Until Appointment` +
                   `Gender of first available female pelvic medicine and reconstructive surgeon` + 
                   #`Accept Medicare` +
                   #`Accepting new patients` +
                   `Insurance type asked before offering appointment` + 
                   `Day of the week the office was called` + 
                   `Hold Time (min)` + 
                   `Length of call (min)` + 
                   `Number of transfers` + 
                   #`Central number` + 
                   `Rurality` + 
                   `American Congress of Obstetricians and Gynecologists District`, data=final, control = mycontrols)

summary(tab1, text=TRUE, title="Characteristics of Female Pelvic Medicine and Reconstructive Surgery Offices Successfully Contacted")

write2word(tab1, "~/Dropbox/Mystery shopper/Results/table1.doc")
