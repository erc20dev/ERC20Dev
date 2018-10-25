pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// ICO smart contract for demo
//
// Demo at: https://erc20dev.com/ico-demo
//
// (c) ERC20Dev, 2018. | https://erc20dev.com
// ----------------------------------------------------------------------------

contract ICO {
    address public owner;
    uint256 public startTime = 1539993600; // ICO starts at 10/20/2018 @ 12:00am (UTC)
    uint256 public bonusPeriodEnd = 1540148399; // Bonus period ends @ 10/21/2018 @ 6:59pm (UTC) / 12pm (PDT)
    uint256 public endTime = 1609459199; // ICO ends at 12/31/2020 @ 11:59pm (UTC)
    uint256 public rate;
    uint256 public tokensSold; // Number of tokens sold
    uint256 public maxTokensSold = 100e24; // 100 million tokens max

    uint256 public etherRaised;
    Token public token;

    // Only allow owner to execute functions
    modifier onlyOwner {
        require(msg.sender == owner,"You can't do that!");
        _;
    }
    
    // Only allow tokens to be purchased during ICO
    modifier duringIcoOnly {
        require(now < endTime && now >= startTime,"ICO is not running");
        _;
    }

    constructor (address _token) public {
        require(_token != address(0),"Address is empty"); //Make sure it's not an empty address
        owner = msg.sender;
        token = Token(_token);
    }

     // Purchase tokens with fallback
    function () public payable duringIcoOnly {
        buyTokens();
    }

    //Purchase tokens directly
    function buyTokens() public payable duringIcoOnly {
        if (now <= bonusPeriodEnd) { // If it is during the bonus period
            rate = 100e18; // 1 ether = 100 tokens
        } else { // But if not
            rate = 50e18; // 1 ether = 50 tokens
        }
        require(tokensSold < maxTokensSold,"Not enough tokens left"); // Only allow if there are enough tokens left
        uint256 tokensPurchased = 0; // How many tokens we are actually getting
        uint256 tokensToBuy = (rate * msg.value) / 1 ether; // Calculate number of tokens buyer wants to buy
        uint256 sumOfTokensToBuy = tokensSold + tokensToBuy; // Check there's enough tokens left
        uint256 _etherRaised = msg.value;
        if (sumOfTokensToBuy > maxTokensSold) { // If buyer wants more tokens than are available
            uint256 exceedingTokens = sumOfTokensToBuy - maxTokensSold; // Calculate excess tokens
            uint256 exceedingEther = (1 ether * exceedingTokens) / rate; // Calculate ether value of excess tokens
            msg.sender.transfer(exceedingEther); // Send ether back
            _etherRaised = _etherRaised - exceedingEther;
            tokensPurchased = maxTokensSold - tokensSold;
        } else { // Otherwise
            tokensPurchased = tokensToBuy; // Give them what they want
        }
        tokensSold += tokensPurchased;
        token.distributeICOTokens(msg.sender, tokensPurchased); // Send the tokens
        etherRaised += _etherRaised;
        owner.transfer(_etherRaised); // Send the ether to the owner

    }

    // Change the rate after deployment but before start
    function changeRate(uint256 _rate) external onlyOwner {
        require(_rate > 0);
        require(now < startTime);
        rate = _rate;
    }

    // Change the owner of the contract
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0),"Address is empty");
        owner = newOwner;
    }
}