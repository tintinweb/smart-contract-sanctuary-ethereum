/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.5.0;

contract Pharmacy {

    address trioms;
    
constructor () public {
        trioms = msg.sender;
    }

modifier onlyAdmin() {
    
    require(msg.sender == trioms, "not owner");
        _;
    }

struct materialMaster{
    string partName;
    uint256 partNo;  // barcode of drugs
    string uom;  // unit of measurement
    string  ABC; // Class of value ABC analysis
    string FMR; // Class of quantity moving , Fast / Medium / Rare
    uint mmrecordno; // Material Master Record No.

}
    uint mmrecordno = 50000000; // Material Master Record No. starting from 50.000.000

mapping(uint256 => materialMaster) MMR;
uint[] partnos;

    // create Material Master Record

function mm01(string memory _partname, uint256 _partno, string memory _uom, string memory _abc, string memory _fmr)
public onlyAdmin returns (uint256){

    mmrecordno++;
    
    MMR[_partno] = materialMaster(_partname, _partno, _uom, _abc, _fmr, mmrecordno);
    
    partnos.push(_partno);
    
    return mmrecordno;
}

// edit Material Master Record

function mm02(string memory _partname, uint256 _partno, string memory _uom, string memory _abc, string memory _fmr)
public onlyAdmin returns (bool){
    
    MMR[_partno] = materialMaster(_partname, _partno, _uom, _abc, _fmr, mmrecordno);
    
    return true;
}

// view Material Master Record

function mm03(uint _partno) external view onlyAdmin returns(string memory, string memory, string memory, string memory, uint){
    

    return (MMR[_partno].partName, MMR[_partno].uom, MMR[_partno].ABC, MMR[_partno].FMR, MMR[_partno].mmrecordno);
}

struct vendorMaster{
    string vendorName;
    uint256 vendorcode;
    string GSTNo;
    string vendorAddress;    //contact person , phone no , postal address
    address vendorWallet; // to transfer token against purchase

}
    uint vendorcode = 10000; // Vendor Master Record No. starting from 10.000

mapping(string => vendorMaster) VMR;
string[] vendorgstnos;

// Create Vendor Master

function mk01(string memory _vendorname, string memory _gst, string memory _vendoradd, address _vwallet)
public onlyAdmin returns (uint256){
    
    vendorcode++;
    
    VMR[_gst] = vendorMaster(_vendorname, vendorcode, _gst, _vendoradd, _vwallet);
    
    vendorgstnos.push(_gst);
    
    return vendorcode;
}

// edit Vendor Master Record

function mk02(string memory _vendorname, string memory _gst, string memory _vendoradd, address _vwallet)
public onlyAdmin returns (bool){
    
    
    VMR[_gst] = vendorMaster(_vendorname, vendorcode, _gst, _vendoradd, _vwallet);
    
    return true;
}

// view Vendor Master Record

function mk03(string memory _gst) public view onlyAdmin returns(string memory, uint, string memory, string memory, address){
    
    return (VMR[_gst].vendorName, VMR[_gst].vendorcode, VMR[_gst].GSTNo, VMR[_gst].vendorAddress, VMR[_gst].vendorWallet);

}

struct infoRecord {
    uint Price;
    uint256 ROQ; // Re order qty
    uint256 MOQ; // Minimum Order Qty
    uint256 PackSize;
    uint16 LT; // Lead time in days
    uint256 ROL; // Re Order Level
    uint24 PaymentTerms; // Payment terms in no. of days
    uint inforecordno;
}

uint inforecordno = 1000000; // Info Record No. starting from 1.000.000

// part code and vendor code are mapped to form an infoRecord

mapping (uint => mapping(uint =>infoRecord)) IR;

// Generate infoRecord

function me11(uint _partno, uint _vendorcode, uint _price, uint _roq, uint _moq, uint _psize, uint16 _lt, uint _rol, uint24 _payment)
public onlyAdmin returns (uint256){
    
    inforecordno++;
    
    IR[_partno][_vendorcode] = infoRecord(_price, _roq, _moq, _psize, _lt, _rol, _payment, inforecordno);
    
    return inforecordno;
}

// edit infoRecord

function me12(uint _partno, uint _vendorcode, uint _price, uint _roq, uint _moq, uint _psize, uint16 _lt, uint _rol, uint24 _payment)
public onlyAdmin returns(bool) {

    IR[_partno][_vendorcode] = infoRecord(_price, _roq, _moq, _psize, _lt, _rol, _payment, inforecordno);
    
    return true;
}
 // view infoRecord
 
    function me13(uint _partno, uint _vcode) public view returns (uint, uint, uint, uint, uint16, uint){
    
    return (IR[_partno][_vcode].Price, IR[_partno][_vcode].ROQ, IR[_partno][_vcode].MOQ, IR[_partno][_vcode].PackSize,
    IR[_partno][_vcode].LT, IR[_partno][_vcode].ROL);
 
    }
    
    struct materialReceipt {
        uint receiptdate ;
        uint partNo;
        uint Qty;
        string uom;
        uint vendorcode;
        uint invoicedate;
        string invoiceno;
        uint materialreceiptno;
        string batchno;
        uint expirydate;
        uint ponumber;
        uint deliverydate;
    }
    
    uint materialreceiptno = 4000000; // Materail Receipt Nos start from 4.000.000
    
    mapping (uint => materialReceipt) MRN;
    mapping(uint => uint) stock;
    
        // capture receipt of goods
        
    function MIGO(uint _partno, uint _vcode, uint _qty, string memory _uom, uint _invdate, string memory _invno, string memory _batchno,
    uint _expiry, uint _ponumber, uint _deliverydate)
    public onlyAdmin returns (uint , string memory){
     
     materialreceiptno++;
     
     MRN[_partno] = materialReceipt(now, _partno, _qty, _uom, _vcode, _invdate, _invno, materialreceiptno, _batchno, _expiry,
     _ponumber, _deliverydate );
    
    stock[_partno] += _qty;
    
    
    // Check if there is delay in receipt from vendor
    
    if (now > _deliverydate){
        return (materialreceiptno, "Material is delivered late");
        
    }else {
        return (materialreceiptno, "Material is delivered On Time");
        
            }

    }
 
    function counterSale (uint _partno, uint _qty) public onlyAdmin returns (uint){
     
     stock[_partno] -= _qty;
     
     return stock[_partno];
    }
 
    // view Stock
    
    function viewStock(uint _partno) public view returns(uint) {
        
        return stock[_partno];
        
    }
    
        // check items due for expiry
        
    uint256[] dueForExpiry;
    
    
    function checkExpiry(uint256 _days) public onlyAdmin returns(uint) {
        
        for (uint i=0; i<partnos.length; i++){
            if ( stock[partnos[i]] > 0) {
                if ( MRN[partnos[i]].expirydate - now < _days){
                dueForExpiry.push(partnos[i]);
                return dueForExpiry[partnos[i]];    
                }
                
             }
        }
        
    }
       // Mark as  Stock Out
    
    function stockOut(uint _partno) public onlyAdmin returns(uint) {
        
        stock[_partno] = 0;
        
        return stock[_partno];
    }
    
    struct MRPData {
        
    uint256 consPerWeek; // consumption per week historical data
    uint256 consPerMonth; // consumption per month historical data
    uint256 consPerQtr; // consumption per Qtr historical data
    uint256 consPerYear; // consumption per year historical data
    uint256 predictionWeek; // Prediction for next 1 week
    uint256 predictionMonth; // Prediction for next 1 month
    
    }
    
    mapping (uint => MRPData ) MRPSet;
    
    // Pull MRPData from AI algorithm or input manually
    
    function setMRPData(uint _partno, uint _cperwk, uint _cpermth, uint _cperqtr, uint _cperyr, uint _pperwk, uint _ppermth)
    public onlyAdmin returns(bool){
        
    MRPSet[_partno] = MRPData(_cperwk, _cpermth, _cperqtr, _cperyr, _pperwk, _ppermth);
    
    return true;
    }
    
    // Part No is Assigned a vendor code
    mapping (uint => uint) FixedVendor;
    
    function fixVendor(uint _partno, uint _vcode) public onlyAdmin returns(bool) {
        
        FixedVendor[_partno] = _vcode;
        
        return true;
    }
    
    // part no to orderquantity
    mapping (uint => uint) PR;
    uint[] PReq;
    
    function MRP() public onlyAdmin returns(bool){
        
        for (uint i=0; i< partnos.length; i++){
            if ( stock[partnos[i]] <= IR[partnos[i]][FixedVendor[partnos[i]]].ROL) {
                // Generate Purchase Requisition
                PR[partnos[i]] = IR[partnos[i]][FixedVendor[partnos[i]]].ROQ;
                PReq.push(partnos[i]);
            }
        }
        return true;
    }
    
    uint ponumber = 6000000; // PO number series starts with 6.000.000
    
    struct PO {
        uint ponumber;
        uint podate;
        uint partNo;
        string partName;
        uint orderquantity;
        uint deliverydate;
        uint Price;
        uint PaymentTerms;
    }
    // PO Number to PO struct
    mapping (uint => PO) POrder;
    uint[] PONumbers;
    
    function me21n () public onlyAdmin returns(uint[] memory) {
        
        for (uint i=0; i<PReq.length; i++){
            POrder[PReq[i]] = PO(ponumber, now, PReq[i], MMR[PReq[i]].partName, PR[PReq[i]], (now + IR[PReq[i]][FixedVendor[PReq[i]]].LT), IR[PReq[i]][FixedVendor[PReq[i]]].Price, IR[PReq[i]][FixedVendor[PReq[i]]].PaymentTerms);
        
            PONumbers.push(ponumber);
            ponumber++;
            PReq.pop();
            
        }
    return PONumbers;
    }
    
}