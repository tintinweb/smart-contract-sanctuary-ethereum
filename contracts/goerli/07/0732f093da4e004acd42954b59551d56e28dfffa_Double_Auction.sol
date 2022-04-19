/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract Double_Auction{
    address owner=msg.sender;

    mapping (address=>uint) public bids;
    mapping (address=> GenerationBid) public Gbids;

    struct MarketBid{
        address marketBen;
        uint price;
        uint quantity;
        bool status;
    }

    struct GenerationBid{
        uint price;
        uint quantity;
    }

    MarketBid[] public MB ;
    MarketBid[] public CB ;

    mapping(address => uint)public pendingReturns;

    event Start();
    event End(bool ended);
    event MBid(address indexed sender, uint price, uint quantity);
    event CBid(address indexed sender, uint price, uint quantity);
    event Withdraw(address indexed bidder, uint amount);
    event ClearingAgreement(address indexed to, address indexed from, uint clearingAmount);

    // constructor(){
    //     owner = msg.sender;
    // }

    function transferOwnership( address _newOwner) public{
        require(msg.sender == owner,"Only Owner can operate");
        owner=_newOwner;
    }

    function ConBid(uint _price) public payable{
        require(msg.value == (_price),"The bid and value doesnot match");
        bids[msg.sender]+=_price;
    }


    function GenBid(uint _price,uint _quantity) public {
        Gbids[msg.sender]=GenerationBid({
            price:_price,
            quantity:_quantity
        });
    }



    function Sellerbid() public {

        MB.push(MarketBid({
            marketBen:msg.sender,
            price:Gbids[msg.sender].price,
            quantity:Gbids[msg.sender].quantity,
            status:false}));

        emit MBid(msg.sender,Gbids[msg.sender].price,Gbids[msg.sender].quantity);
    }

    function Consumptionbid(uint _quantity) public{

        CB.push(MarketBid({
            marketBen:msg.sender,
            price:bids[msg.sender],
            quantity:_quantity,
            status:false}));

        emit CBid(msg.sender,bids[msg.sender],_quantity);
    }


    function SortSeller() public {
        require(msg.sender == owner,"Only Owner can operate");

        for(uint i=0;i<MB.length-1;i++){
            for(uint j=0;j<MB.length-i-1;j++){
                if (MB[j].price > MB[j+1].price)
                {
                    // swap arr[j+1] and arr[j]
                    MarketBid memory temp = MB[j];
                    MB[j] =MB[j+1];
                    MB[j+1] = temp;
                }

            }

        }
    }

    function SortConsumer() public {
        require(msg.sender == owner,"Only Owner can operate");

        for(uint i=0;i<CB.length-1;i++){
            for(uint j=0;j<CB.length-i-1;j++){
                if (CB[j].price < CB[j+1].price)
                {
                    // swap arr[j+1] and arr[j]
                    MarketBid memory temp = CB[j];
                    CB[j] =CB[j+1];
                    CB[j+1] = temp;
                }

            }

        }
    }

    function Clearing() public payable{
        uint i=0;
        uint j=0;
        for(i=0;i<MB.length;i++){
            for(j=0;j<CB.length;j++){
                if(CB[j].status==false && MB[i].status==false){
                    if(((CB[j].price)>=(MB[i].price/MB[i].quantity*CB[j].quantity)) && CB[j].quantity<=MB[i].quantity){
                        
                        uint clearingAmount= (((MB[i].price/MB[i].quantity)*CB[j].quantity)+CB[j].price)/2;
                        payable(MB[i].marketBen).transfer(clearingAmount);
                        payable(CB[j].marketBen).transfer((CB[j].price-clearingAmount));
                        MB[i].quantity=MB[i].quantity-CB[j].quantity;
                        CB[j].quantity=0;
                        CB[j].status=true;

                        emit ClearingAgreement(MB[i].marketBen,CB[i].marketBen,clearingAmount);

                        if(MB[i].quantity==0){
                            MB[i].status=true;
                        }
                    }
                }
                if(MB[i].status==true){
                            break;
                        }
            }
        }
        emit End(true);

    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if(amount>0){
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);

            emit Withdraw(msg.sender,amount);
            
        }
    }

    function balanceOf()public view returns  (uint){
        uint amountB = address(this).balance;
        return amountB;

    }

    function MarketSize() public view returns (uint){
        return MB.length;
    }

    function ConsumerSize() public view returns (uint){
        return CB.length;
    }

}