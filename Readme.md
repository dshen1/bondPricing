# Introduction to git

http://cgroll.github.io/research_tools/output/git.slides.html#/

# private git

- private repositories can be hosted on [gitlab](https://about.gitlab.com/)

# Including repositories as submodules

- git submodule add git@gitlab.com:cgroll/priv_bondPriceData.git
- git submodule init 
- git submodule update

# TODOs:

- compare simulated prices to real US bond ETF
- simulate bond ETF for different made-up interest rate scenarios: 
	- flat curve with high level of interest rates
	- flat curve with low level of interest rates
	- reflected rates: flip evolution from left to right
	- two times equal average interest rates, one with increasing
     tendency, one with decreasing tendency

- display message backtestRollingStrategy: percentage values

Individual steps:
- simulate interest rates
- simulate existing bonds and their prices
- simulate strategy
- portfolio values of strategy is simulated ETF price
