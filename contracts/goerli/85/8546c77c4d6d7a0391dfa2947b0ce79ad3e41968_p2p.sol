/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// File: https://github.com/opengsn/gsn/blob/master/packages/contracts/src/interfaces/IERC2771Recipient.sol


pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// File: https://github.com/opengsn/gsn/blob/master/packages/contracts/src/ERC2771Recipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;


/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: bibp2p.sol



pragma solidity ^0.8.7;
contract p2p is ERC2771Recipient{
    address payable owner;

    event check(uint256 indexed _id);
    struct enter {
        address payable owner;
        uint256 low;
        uint256 high;
        uint256 deposite;
        uint256 price;
        bool active;
        uint256 id;
        string paymentoptions;
        uint256 orders;
        uint8 ordersmissed;
    }
   enter[] public ledger;

   constructor(address _trustedForwarder) {
   _setTrustedForwarder(_trustedForwarder);
   owner=payable(msg.sender);
   }

   function versionRecipient() external pure  returns (string memory) {
        return "1";
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "");
        _;
    }
       function setTrustForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }
 

    function createOrder(uint256 low,uint256 high,bool active,uint256 price,string memory paymentoptions) public payable{
        enter memory enter1;
        enter1.owner=payable(msg.sender);
        enter1.low=low;
        enter1.high=high;
        enter1.price=price;
        enter1.deposite=msg.value;
        enter1.active=active;
        enter1.id=orders.length;
        enter1.paymentoptions=paymentoptions;
        ledger.push(enter1);
    }
    
    function getledger()public view returns(enter[] memory ledge) {
        return ledger;
    }
    function updateOrder(uint256 low,uint256 high,bool active,uint256 price,uint256 id,string memory paymentoptions) public payable{
        require(orders[id].owner==msg.sender,"not owner");
        ledger[id].price=price;
        ledger[id].deposite+=msg.value;
        ledger[id].active=active;
        ledger[id].low=low;
        ledger[id].high=high;
        ledger[id].paymentoptions=paymentoptions;
    }

    function verfiy(uint256 orderid,bool sent) public{
        require(ledger[orders[orderid].enterid].owner==msg.sender,"you are not owner");
        if(sent == true){
            orders[orderid].respond=process.verfiyed;
        ledger[orders[orderid].enterid].deposite -=orders[orderid].amount;
        (orders[orderid].owner).transfer(orders[orderid].amount);
        ledger[orders[orderid].enterid].orders++;

        }else{
        orders[orderid].respond=process.falserequest;
        orderstovalidate[ledger[orders[orderid].enterid].id]=orderid;
         emit check(orderid);
        }
    }

   struct order{
       uint256 enterid;
       uint256 amount;
       address payable owner;
       process  respond; 
       uint256 price;
       uint256 ordernumber;
   }

   order[] public orders;
   enum process{ tobereview, verfiyed,falserequest,  validatorsreview ,invalidrequest}

   function paided(uint256 amount,uint id) public{
       require(ledger.length>id,"not enter");
       require(ledger[id].active==true," not active");
       require(ledger[id].deposite>=amount," higher amount");
       require((amount>=ledger[id].low)&&(amount<=ledger[id].high),"not in range");
       require(orderstovalidate[id]==0,"can't pay now");
        order memory order1;
        order1.enterid=id;
        order1.amount=amount;
        order1.owner=payable(msg.sender);
        order1.respond=process.tobereview;
        order1.ordernumber= block.number;
        order1.price=ledger[id].price;
        orders.push(order1);
   }

      function relaypaided(uint256 amount,uint id) public{
       require(ledger.length>id,"not enter");
       require(ledger[id].active==true," not active");
       require(ledger[id].deposite>=amount," higher amount");
       require((amount>=ledger[id].low)&&(amount<=ledger[id].high),"not in range");
       require(orderstovalidate[id]==0,"can't pay now");
        order memory order1;
        order1.enterid=id;
        order1.amount=amount;
        order1.owner=payable(_msgSender());
        order1.respond=process.tobereview;
        order1.ordernumber= block.number;
        order1.price=ledger[id].price;
        orders.push(order1);
   }


   function requestverfiy(uint256 orderid) public{
       require(orders.length>orderid,"doesn't exist");
       require(30 >=( block.number - orders[orderid].ordernumber),"can't apply for verfication");
       require(orders[orderid].respond==process.falserequest ,"already verfiyed");
       orderstovalidate[orders[orderid].enterid]=orderid;
       orders[orderid].respond=process.validatorsreview;
   }



   //Vallidaters

   mapping(uint256=>uint256)public orderstovalidate;

  function Govern(uint256 orderid,bool sent) public{
      require(msg.sender==owner,"not owner");
      require(orderstovalidate[orders[orderid].enterid]==orderid,"not request");

        if(sent == true){
        orders[orderid].respond=process.verfiyed;
        ledger[orders[orderid].enterid].deposite -=orders[orderid].amount;
        (orders[orderid].owner).transfer(orders[orderid].amount);
        ledger[orders[orderid].enterid].ordersmissed++;
        }else{
        orders[orderid].respond=process.invalidrequest;
        }
        orderstovalidate[orders[orderid].enterid]=0;
  }


}