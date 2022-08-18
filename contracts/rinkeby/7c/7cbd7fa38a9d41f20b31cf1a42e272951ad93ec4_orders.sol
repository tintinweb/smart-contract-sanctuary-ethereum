// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './SafeMath.sol';

contract orders {
    using SafeMath for uint256;
     /// @notice Explain to an end user what this does
        /// @dev Explain to a developer any extra details
        /// @return Documents the return variables of a contract’s function state variable
        /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    enum  status {Created, DownPaid, Paid,  Shipped, Dispatched, Released, Delivered, Completed} 


     struct  order {
        uint256 invoice_no;
        string picUrl;
        uint256 preshipment;//SGS
        uint256 handlingcost;//HAB
        uint256 seafreight;//BOL
        uint256 shippinglinecost;
        uint256 kpa; //KPA release order
        uint256 taxes; //Custom entry
        uint256 kebs; //Conformity
        uint256 transport;//delivery order
        uint256 price; //invoice
        status Status;
    }

    

    mapping (uint256 => order) public sortOrder;
    mapping (uint256 => uint256) public payment;
    mapping (uint256 => uint256) public total;
    mapping (uint256 => uint256) public agency;

    event created(uint256 invoice, string  pictureUrl);
    event accepted(uint256 invoice, uint256  price);
    event downpayment(uint256 invoice, uint256  payment);
    event agencyFee(uint256 invoice, uint256  fee);

    function  createOrder(string memory _picUrl) public returns (uint256){
        uint256 _invoice = invoiceNum();
        sortOrder[_invoice].invoice_no = _invoice;
        sortOrder[_invoice].picUrl= _picUrl;
        sortOrder[_invoice].Status = status.Created;

        emit created(_invoice, _picUrl);
        return _invoice;
     
    }

    function acceptOrder (uint256 _invoice, uint256 _price) public returns (uint256, uint256){
        sortOrder[_invoice].price = _price;
        //sortOrder[_invoice].agency = _pri;
        setTotal(_invoice, _price);
        
        emit accepted(_invoice, _price);
        return (_invoice, _price);

    }

    function setTotal (uint256 _invoice, uint256 _add) internal {
       total[_invoice] =  total[_invoice].add(_add);    

    }
    
    function payIt (uint256 _invoice, uint256 _paid) internal {
       payment[_invoice] =  payment[_invoice].add(_paid);    

    }

     function invoiceNum() private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%259);
    } 

    function downPayOrder(uint256 _invoice, uint256 _payment) public returns (uint256){
        uint256 _price = payment[_invoice];
        require(_payment <= _price, "Downpayment must be less than total");
        payment[_invoice].add(_payment);
        //sortOrder[_invoice].payment.add(_payment);
        
        sortOrder[_invoice].Status = status.DownPaid;
        emit downpayment(_invoice, _payment);
        return payment[_invoice];
    }
   
   function payAgencyFee (uint256 _invoice, uint256 _fee) public returns (uint256, uint256){
        agency[_invoice] = _fee;
        //sortOrder[_invoice].agency = _pri;
        setTotal(_invoice, _fee);
        
        emit agencyFee(_invoice, _fee);
        return (_invoice, _invoice);

    }



}