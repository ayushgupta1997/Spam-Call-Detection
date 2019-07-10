class SpamCheck:
    SpamDict = {
        'atm' : 0, 'block' : 0, 'unblock' : 0, 'mobile' : 0, 'verify' : 0, 'card' : 0, 'cvv' : 0, 'expiry' : 0, 'otp' : 0, 'pin' : 0, 'validity': 0,
        'number' : 0, 'month' : 0, 'year' : 0, 'date' : 0, 'bank' : 0
        }
    def __init__ (self, text):
        self.text = text
        
        
    def generateList(self):
        self.wordlist = list(self.text.split(' '))
        

    def generateDict(self):
        self.generateList()
        for word in self.wordlist:
            try:
                if self.SpamDict[word] == 0:
                    self.SpamDict[word] = 1 
            except KeyError:
                pass
      
    def checkSpam(self):
        
        self.generateDict()
        self.count = 0
        for word in self.SpamDict:
            if self.SpamDict[word] == 1:
                self.count += 1
		if self.count > 3:                                          #Here we have tken 3 as threshold if more than three spam word contain in our sentence
			return 'Off the phone call, It is spam call'            #then it is spam call
                
        return 'Continue Phone call'
            
            



if __name__ == '__main__':
    text = "hello my name is shubham kumar month pin".lower()
    sp  = SpamCheck(text)
    #print(SpamDict)
    #print(sp.checkSpam())
    print(sp.checkSpam())
       



