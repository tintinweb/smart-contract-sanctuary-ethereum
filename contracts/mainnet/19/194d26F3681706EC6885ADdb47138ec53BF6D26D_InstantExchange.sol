/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract InstantExchange {
    
    /**
    * handle exchange tokens
    */
    IERC20 aln;
    IERC20 usdt;
    constructor(address _usdtAddress,address _alnAddress){
        owner = msg.sender;
        usdt = IERC20(_usdtAddress);
        aln = IERC20(_alnAddress);
        exchangeRate = 20*1000;
        modify_partners (msg.sender, 1000);
    }

    /**
    * handle ownership
    */
    address public owner;
    modifier onlyOwner {
        require(msg.sender==owner,"Only owner");
        _;
    }
    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }


    /**
    * handle Partners
    */
    mapping(uint => Partner) public partners;
    mapping(address=>uint) public partnerIds;
    struct Partner{
        address partner_address;
        uint share;
    }
    uint public total_share;
    uint public total_partners;
    function modify_partners (address partnerAddress, uint share) public onlyOwner{

        uint partnerId = partnerIds[partnerAddress];

        if(share==0) // case of remove partner
        {
            require(partnerId>0,"Invalid partner");
            require(total_partners>1,"No Partner will remain");

            for(uint i=partnerId;i<total_partners;i++){
                partnerIds[partners[i+1].partner_address] = i;
                partners[i] = partners[i+1];
            }

            delete partners[total_partners];
            delete partnerIds[partnerAddress];

            total_share -= partners[partnerId].share;
            total_partners--;

            return;
        }

        if (partnerId > 0)
        {
            total_share -= partners[partnerId].share;
            total_share += share;
            partners[partnerId].share = share;
        }else{
            total_partners++;
            partnerId = total_partners;
            partnerIds[partnerAddress] = total_partners;

            total_share += share;
            partners[partnerId].share = share;
            partners[partnerId].partner_address = partnerAddress;
            partnerIds[partnerAddress] = total_partners;
        }
    }
    function claim_income () private{
        //get balance
        uint balance = usdt.balanceOf(address(this));

        uint payable_shares;
        for(uint8 i=1;i<=total_partners;i++){ //ignore partner id 0 
            payable_shares = ( balance *  partners[i].share) / total_share ;
            usdt.transfer(partners[i].partner_address,payable_shares);
        }
    }

    /**
    * handle exchange
    */
    uint public exchangeRate ;// devision by 1000 required. 1234 means 1.234
    function setExchangeRate(uint _exchangeRate) public onlyOwner{
        exchangeRate = _exchangeRate;
    }
    function exchange(uint _amountUsdt) public{
        //receive usdt
        usdt.transferFrom(msg.sender,address(this),_amountUsdt);
        
        //send aln
        uint transferAmount = _amountUsdt * exchangeRate/1000;
        aln.transfer(msg.sender,transferAmount);

        //distribute shares
        claim_income();
    }
}

pragma solidity ^0.8.7;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}