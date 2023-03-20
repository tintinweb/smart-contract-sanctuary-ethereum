/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract BuzzMe {
    

    struct Collector {
        string buzzName;
        address payable getter;
        uint256 amount;
    }
    
    //mapping(address=>Collector) collectors;
    mapping(string=>mapping(address=>Collector)) collectors;
    
    address[] collectors_addresses;
    string[] collectors_buzzname;

    event buzzBalance(uint256 buzzAmount);
    function createBuzz(string memory _buzzname) external {
        Collector memory newcollector = Collector(_buzzname,payable(msg.sender),0);
        collectors[_buzzname][msg.sender] = newcollector;
        collectors_addresses.push(msg.sender);
        collectors_buzzname.push(_buzzname);
    }

    /**
     * @dev gets all collectors transaction
     */
    function getAllBuzzme() public view returns (Collector[] memory) {
        
        Collector[] memory collectors_Array = new Collector[](collectors_addresses.length);
        for (uint i = 0; i < collectors_addresses.length; i++) {

            Collector memory collector = collectors[collectors_buzzname[i]][collectors_addresses[i]];
            collectors_Array[i] = collector;
        }
        return collectors_Array;
    }


    /**
     * @dev buzzMeEth for collector . sends an ETH to the receiver
     * @param _getter address of the buzz giver
     * @param _buzzname name of the buzzme
     */
    function buzzMeEth(address _getter, string memory _buzzname) public payable {
        
        require(msg.value > 0, "can't send 0 eth!");

        collectors[_buzzname][_getter].amount += msg.value;

        emit buzzBalance( collectors[_buzzname][_getter].amount);

    }

    /**
     * @dev send the entire balance of the collector
     */
    
    function withdrawBuzz(address payable _getter, string memory _buzzname) payable public {
        //require(owner.send(address(this).balance));
        uint256 amount = collectors[_buzzname][_getter].amount;
        require(amount>0,"you have no buzz yet!");
        require(amount<=address(this).balance);
        _getter.transfer(amount);
        collectors[_buzzname][_getter].amount -= amount;

    }
}