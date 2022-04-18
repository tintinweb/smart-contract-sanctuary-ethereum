/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

pragma solidity ^0.8.2;

// SPDX-License-Identifier: MIT



library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TheGmFansStudio {
    
    using SafeMath for uint256;
    
    enum CommissionStatus { queued, accepted, removed  }

    struct Shop {
        uint256 minBid;
        uint256 tax;
    }
    
    struct Commission {
        address payable recipient;
        uint256 shopId;
        uint256 bid; 
        CommissionStatus status;
    }


    uint MAX_INT = uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);


    address payable public admin;
    address payable public receiptentDao;
    
    mapping (uint => Commission) public commissions;
    mapping (uint256 => Shop) public shops;
    
    //uint public minBid; // the number of wei required to create a commission
    uint256 public newCommissionIndex; // the index of the next commission which should be created in the mapping
    uint256 public newShopIndex;
    bool public callStarted; // ensures no re-entrancy can occur

    modifier callNotStarted () {
      require(!callStarted, "callNotStarted");
      callStarted = true;
      _;
      callStarted = false;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin, "not an admin");
        _;
    }
    
    constructor(address payable _admin, address payable _receiptentDao) {
        admin = _admin;
        receiptentDao = _receiptentDao;
        newCommissionIndex = 1;
        newShopIndex = 1;
    }
    
     
    function updateAdmin (address payable _newAdmin)
    public
    callNotStarted
    onlyAdmin
    {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }
    
    function updateMinBid (uint256 _shopId, uint256 _newMinBid)
    public
    callNotStarted
    onlyAdmin
    {
        Shop storage shop = shops[_shopId];
        shop.minBid = _newMinBid;
        emit MinBidUpdated(_shopId, _newMinBid);
    }
   
    function commission (string memory _id, uint256 _shopId) 
    public
    callNotStarted
    payable
    {   
        Shop memory shop = shops[_shopId];
        require(shop.minBid != 0, "undefined shopId");
        require(msg.value >= shop.minBid, "bid below minimum"); // must send the proper amount of into the bid
        
        // Next, initialize the new commission
        Commission storage newCommission = commissions[newCommissionIndex];
        newCommission.shopId = _shopId;
        newCommission.bid = msg.value;
        newCommission.status = CommissionStatus.queued;
        newCommission.recipient = payable(msg.sender);
              
        emit NewCommission(newCommissionIndex, _id, _shopId, msg.value, msg.sender);
        
        newCommissionIndex++; // for the subsequent commission to be added into the next slot 
    }
    
    function batchCommission (string[] memory _ids, uint256[] memory _shopIds, uint256[] memory _bids ) 
    public
    callNotStarted
    payable
    {
        require(_ids.length == _bids.length, "arrays unequal length");
        uint sum = 0;
        
        for (uint i = 0; i < _ids.length; i++){
          Shop memory shop = shops[_shopIds[i]];
          require(shop.minBid != 0, "undefined shopId");
          require(_bids[i] >= shop.minBid, "bid below minimum"); // must send the proper amount of into the bid
          // Next, initialize the new commission
          Commission storage newCommission = commissions[newCommissionIndex];
          newCommission.shopId = _shopIds[i];
          newCommission.bid = _bids[i];
          newCommission.status = CommissionStatus.queued;
          newCommission.recipient = payable(msg.sender);

                
          emit NewCommission(newCommissionIndex, _ids[i], _shopIds[i], _bids[i], msg.sender);
          
          newCommissionIndex++; // for the subsequent commission to be added into the next slot 
          sum += _bids[i];
        }
        
        require(msg.value == sum, "insufficient funds"); // must send the proper amount of into the bid
    }
    
    function rescindCommission (uint _commissionIndex) 
    public
    callNotStarted
    {
        require(_commissionIndex < newCommissionIndex, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued
      
        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        selectedCommission.recipient.transfer(selectedCommission.bid);
        
        emit CommissionRescinded(_commissionIndex);
    }
    
    function increaseCommissionBid (uint _commissionIndex)
    public
    payable
    callNotStarted
    {
        require(_commissionIndex < newCommissionIndex, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued

        // then we update the commission's bid
        selectedCommission.bid = msg.value + selectedCommission.bid;
        
        emit CommissionBidUpdated(_commissionIndex, selectedCommission.bid);
    }
    
    function processCommissions(uint[] memory _commissionIndexes)
    public
    onlyAdmin
    callNotStarted
    {
        for (uint i = 0; i < _commissionIndexes.length; i++){
            Commission storage selectedCommission = commissions[_commissionIndexes[i]];
            
            require(selectedCommission.status == CommissionStatus.queued, "commission not in the queue"); // the queue my not be empty when processing more commissions 
            
            selectedCommission.status = CommissionStatus.accepted; // first, we change the status of the commission to accepted
            admin.transfer(selectedCommission.bid); // next we accept the payment for the commission
            
            emit CommissionProcessed(_commissionIndexes[i], selectedCommission.status);
        }
    }
    
    function addShop(uint256 _minBid, uint256 _tax)
    public
    onlyAdmin
    {

      require(_minBid != 0, "minBid must not zero");
      Shop storage shop = shops[newShopIndex];
      shop.minBid = _minBid;
      shop.tax = _tax;

      emit ShopAdded(newCommissionIndex, _minBid,  _tax);
      newCommissionIndex++;
      
    }

    event AdminUpdated(address _newAdmin);
    event MinBidUpdated(uint256 _shopId, uint256 _newMinBid);
    event NewCommission(uint _commissionIndex, string _id, uint256 _shopId, uint _bid, address _recipient);
    event CommissionBidUpdated(uint _commissionIndex, uint _newBid);
    event CommissionRescinded(uint _commissionIndex);
    event CommissionProcessed(uint _commissionIndex, CommissionStatus _status);
    event ShopAdded(uint256 newCommissionIndex, uint256 _minBid, uint256 _tax);
}