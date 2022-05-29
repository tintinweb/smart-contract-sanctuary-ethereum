// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;




contract ETHFaucetDemo{

 uint256 totalTxs;
 
 mapping(address => uint256) public lastSentTime;
 event NewTx(address indexed from, uint256 timestamp);

    receive() external payable {
        // you can leave this function body empty
    }

    constructor() payable {
  
}



    function sendETHFromFaucet(uint256 _amount) public {
        require(
            lastSentTime[msg.sender] + 1 days < block.timestamp,
            "Wait 1 day"
        );

        /*
         * Update the current timestamp we have for the user
         */
        lastSentTime[msg.sender] = block.timestamp;
        totalTxs += 1;
      

         emit NewTx(msg.sender, block.timestamp);
         
    require(
        _amount <= address(this).balance,
        "Trying to withdraw more money than the contract has."
    );
    (bool success, ) = (msg.sender).call{value: _amount}("");
    // (msg.sender).call{value: prizeAmount}("");
    require(success, "Failed to withdraw money from contract.");
}
    

    function getTotalTxs() public view returns (uint256) {
       
        return totalTxs;
    }

  

    function getSentTime()public view returns (uint256) {
       
        return lastSentTime[address(this)];
    }



}