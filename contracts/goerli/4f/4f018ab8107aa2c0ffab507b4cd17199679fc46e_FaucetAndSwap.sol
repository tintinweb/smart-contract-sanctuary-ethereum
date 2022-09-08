/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0 <0.9.0;

interface IUSDT {
    function transfer(address to, uint amount) external;
}

contract FaucetAndSwap {
	address public me;
    	address immutable usdtAddress; 

	struct requester {
        address requesteraddress;
        uint amount;
    }
    
    requester[] public requesters;

	constructor(address _address) payable {
		me = msg.sender;
        usdtAddress = _address; // Заносим адрес предварительно созданного токена
	}

	event sent(uint _amountsent);
	event received();

	receive() external payable
	{
		emit received();
	}

    function send(address payable _requester, uint256 _request)
        public
        payable
    {
        require(msg.sender == me, 'Only owner!');

        uint amountsent = 0;
        uint limit = 0.2 * 1e18;
        
        require(limit >= _request, 'The maximum amount cannot exceed 0.2 ETH!');

        // TODO: Need to set sender limit
        if (address(this).balance > _request){
            amountsent = _request/1e18; 
            _requester.transfer(_request);
        }
        else{
            amountsent = (address(this).balance)/1e18; 
            _requester.transfer(address(this).balance);
        }
        
        requester memory r;
        r.requesteraddress = _requester;
        r.amount = amountsent;
        requesters.push(r);
        emit sent(amountsent);
    }

    function swapEthForUsdt(uint _value) external payable { 
        require (msg.value > 0, "Swap: U have to send Ether");
        require (msg.value < 1e17, "Swap: Too much Ether");
        require (_value <= 100e18, "Swap: The maximun amount cannot exceed 100 USDT");
        
        IUSDT(usdtAddress).transfer(msg.sender, _value); 
    }
}