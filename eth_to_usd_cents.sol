pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// Contract to fetch current price of 1 ETH in US cents using Oraclize and
// the Coinbase.com ETH price
//
// (c) ERC20Dev, 2018. | https://erc20dev.com
// ----------------------------------------------------------------------------

import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.25.sol";

contract EthToUSCents is usingOraclize {

    address owner;
    string public ETHUSD; // Price of 1 ETH in USD
    uint256 public ethConverted; // Price of 1 ETH in cents

    event LogInfo(string description);
    event LogPriceUpdate(string price);
    event LogUpdate(address indexed _owner, uint indexed _balance);

    // Constructor
    function OraclizeETHUSD() payable public {
        owner = msg.sender;
        emit LogUpdate(owner, address(this).balance);
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update();
    }

    // Fallback function
    function()
    public{
        revert();
    }

    function __callback(bytes32 id, string result, bytes proof)
    public {
        require(msg.sender == oraclize_cbAddress());
        ETHUSD = result;
        ethConverted = parseInt(result, 2); // Convert the result to uint256
        emit LogPriceUpdate(ETHUSD);
        update();
    }

    function getBalance() public returns (uint _balance) {
        return address(this).balance;
    }
    
    function update()
    payable
    public {
        // Check if we have enough remaining funds
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogInfo("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogInfo("Oraclize query was sent, standing by for the answer..");

            // Using XPath to to fetch the right element in the JSON response
            oraclize_query("URL", "json(https://api.coinbase.com/v2/prices/ETH-USD/spot).data.amount");
        }
    }
}