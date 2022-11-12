/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
// File: Access.sol


pragma solidity ^0.8.7;

contract Access {

    address public calibTech1 = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;
    address public calibTech2 = 0x3B05C893b88212061C7C4e14c78fcd4E16917BCb;
    address public calibTech3 = 0x583031D1113aD414F02576BD6afaBfb302140225;
    address public calibTech4 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public calibTech5 = 0x03F12330c8007803C2f9E10f4eae17F3A1a7af9F;
    address public vendor1 = 0x3B05C893b88212061C7C4e14c78fcd4E16917BCb;
    address public vendor2 = 0xB4c89d5f39f3B398A46d5b2cd0aD750b38AD46DB;
    address public vendor3 = 0x00f23F18F84fC82cA7bf95df586B87bE116F53bA;
    address public manager = 0x6a07bB46D93c4BF298E1aCf67bDBd163e7B793c6; 
    address public calibTech6;
    address public calibTech7;
    address public calibTech8;
    address public calibTech9;
    address public calibTech10;
    address public vendor4;
    address public vendor5;
    address public vendor6;

    modifier onlyCalibTech(){
        require(msg.sender == calibTech1 || msg.sender == calibTech2 || msg.sender == calibTech3 
        || msg.sender == calibTech4 || msg.sender == calibTech5 || msg.sender == calibTech6 || 
        msg.sender == calibTech7 || msg.sender == calibTech8 ||msg.sender == calibTech9 || msg.sender == calibTech10, "Call: Only Calibration Tech Team");
        _;
    }

    modifier onlyVendor(){
        require(msg.sender == vendor1 || msg.sender == vendor2 || msg.sender == vendor3 ||
         msg.sender == vendor4 || msg.sender == vendor5 || msg.sender == vendor6, "Call: Only Vendor");
        _;
    }
    
    modifier onlyManager(){
        require(msg.sender == manager, "Call: Only Manager");
        _;
    }

        modifier CalibMang(){
        require(msg.sender == calibTech1 || msg.sender == calibTech2 || msg.sender == calibTech3 
        || msg.sender == calibTech4 || msg.sender == calibTech5 || msg.sender == calibTech6 || 
        msg.sender == calibTech7 || msg.sender == calibTech8 ||msg.sender == calibTech9 || msg.sender == calibTech10 || msg.sender == manager, "Call: Calibration or Manager Only!");
        _;
    }

  modifier CalibVendMan(){
        require(msg.sender == calibTech1 || msg.sender == calibTech2 || msg.sender == calibTech3 
        || msg.sender == calibTech4 || msg.sender == calibTech5 || msg.sender == calibTech6 || 
        msg.sender == calibTech7 || msg.sender == calibTech8 ||msg.sender == calibTech9 || msg.sender == calibTech10
        || msg.sender == vendor1 || msg.sender == vendor2 || msg.sender == vendor3 ||
         msg.sender == vendor4 || msg.sender == vendor5 || msg.sender == vendor6 || msg.sender == manager, "Call: Calibration, Vendor, Manager Only!");
        _;
    }
    
    function changeAddressC1(address c1) public onlyManager returns(bool) {
        calibTech1 = c1;
        return true;
    }

     function changeAddressesC2(address c2) public onlyManager returns(bool) {
        calibTech2 = c2;
        return true;
    }
     function changeAddressesC3(address c3) public onlyManager returns(bool) {
        calibTech3 = c3;
        return true;
    }
     function changeAddressesC4(address c4) public onlyManager returns(bool) {
        calibTech4 = c4;
        return true;
    }
     function changeAddressesC5(address c5) public onlyManager returns(bool) {
        calibTech5 = c5;
        return true;
    }
     function changeAddressesV1(address v1) public onlyManager returns(bool) {
        vendor1 = v1;
        return true;
    }
     function changeAddressesV2(address v2) public onlyManager returns(bool) {
        vendor2 = v2;
        return true;
    }
     function changeAddressesV3(address v3) public onlyManager returns(bool) {
        vendor3 = v3;
        return true;
    }

    function changeManager(address _manager) public onlyManager returns(bool) {
        manager = _manager;
        return true;
    }


}
// File: Database.sol


pragma solidity ^0.8.7;


contract Database is Access{

    struct tmde{
        uint256 assetTag;
        string Type;
        address vendor;
        bool inUse;
        bool due; 
        uint256 lastCalibDate;  //last time the TMDE was serviced
        uint256 nextCalibDate;  //next time TMDE needs to be serviced
    }
    
    mapping (uint256 => tmde) public tagToTMDE;
    mapping (uint256 => uint256) public serCgs;
    mapping (uint256 => address) public chargesSender;
    mapping (uint256 => state) public STATE;
    mapping (address => tmde[]) public tfMem;

    event DueForCalibration(uint256 indexed assetTag);
    event CalibrationPassed(uint256 assetTag, uint256 _certificate, uint256 _nextCalibDate);
    event calibrationFailed(uint256 assetTag, uint256 _invoice, uint256 _costToService);
    event InvoiceApproved(uint256 _assetTag, uint256 _invoice, uint256 _charges);
    event InvoiceRejected(uint256 _asset);

    enum state {
        Informed, calibPassed, calibFailed, inApproved
    }

    tmde[] internal TMDE;
    uint256 public currentSerCgs;

    struct scrapParts{
        uint256 assetTag;
        string Type;
        address vendor;
    }

    scrapParts [] internal ScrapParts;

    function createTMDE(uint256 _assetTag, string memory _Type, address _vendor, bool _status, uint256 _lastCalibDate, uint256 _nextCalibDate) public CalibMang returns (bool){
        for(uint i = 0 ; i<TMDE.length ; i++){
            require(_assetTag != TMDE[i].assetTag, "TMDE registered already!");
        }
        require(_vendor == vendor1 || _vendor == vendor2 || _vendor == vendor3 ||
        _vendor == vendor4 || _vendor == vendor5 || _vendor == vendor6 , "Vendor not Present");
        if(_status == true){
            TMDE.push(tmde(_assetTag, _Type, _vendor, false,true, _lastCalibDate, _nextCalibDate));
        }
        else {
            TMDE.push(tmde(_assetTag, _Type, _vendor, true,false, _lastCalibDate, _nextCalibDate));
        }
        tfMem[_vendor].push(tmde(_assetTag, _Type, _vendor, false,true, _lastCalibDate, _nextCalibDate));
        return true;
    }

    function updateTMDE(uint256 _assetTag, string memory _Type, bool _status, uint256 _lastCalibDate, uint256 _nextCalibDate) public CalibMang returns (bool){
        address v;
        for(uint i = 0 ; i<TMDE.length ; i++){
            if(TMDE[i].assetTag == _assetTag){
                v = TMDE[i].vendor;
            }
        }
        for(uint i = 0 ; i<TMDE.length ; i++){
            if(TMDE[i].assetTag == _assetTag){
                if(_status == true){
                    TMDE[i].due = _status;
                    TMDE[i].inUse = false;
                    tfMem[v][i].due = _status;
                    tfMem[v][i].inUse = false;
                }
                else if(_status == false){
                    TMDE[i].due = _status;
                    TMDE[i].inUse = true;
                    tfMem[v][i].due = _status;
                    tfMem[v][i].inUse = true;
                }
                TMDE[i].Type = _Type;
                TMDE[i].lastCalibDate = _lastCalibDate;
                TMDE[i].nextCalibDate = _nextCalibDate;
                tfMem[v][i].Type = _Type;
                tfMem[v][i].lastCalibDate = _lastCalibDate;
                tfMem[v][i].nextCalibDate = _nextCalibDate;
            }
        }
        return true;
    }

//Show scrap tmde Info
    function ScraptmdeInfo() public view returns(scrapParts [] memory){
        return ScrapParts;
    }

//For Calibration and manager to view all tmde
    function alltmdeInfo() public view CalibVendMan returns( tmde [] memory){
        if(msg.sender == vendor1 || msg.sender == vendor2 || msg.sender == vendor3 ||
         msg.sender == vendor4 || msg.sender == vendor5 || msg.sender == vendor6){
            return (tfMem[msg.sender]);
        }
        else{
        return (TMDE);
        }
    }

    function addCalibrationT(address _tech) public onlyManager returns (bool){
        if(calibTech6 == address(0)){
        calibTech6 = _tech;
        }
        else if(calibTech7 == address(0)){
            calibTech7 = _tech;
        } 
        else if(calibTech8 == address(0)){
            calibTech8 = _tech;
        } 
        else if(calibTech9 == address(0)){
            calibTech9 = _tech;
        } 
        else if(calibTech10 == address(0)){
            calibTech10 = _tech;
        } 
        else{
            revert("All addresses are reserved!");
        }
        return true;
    }

    function addVendor(address _vendor) public onlyManager returns (bool){
        if(vendor4 == address(0)){
        vendor4 = _vendor;
        }
        else if(vendor5 == address(0)){
            vendor5 = _vendor;
        } 
        else if(vendor6 == address(0)){
            vendor6 = _vendor;
        }
        else{
            revert("All addresses are reserved!");
        }
        return true;
    }

    function getCalibAddress() public view returns(address, address, address, address,address, address, address, address,
    address,address){
        return(calibTech1, calibTech2, calibTech3, calibTech4, calibTech5, calibTech6 ,calibTech7
        , calibTech8, calibTech9, calibTech10);
    }

     function getVendAddress() public view returns(address, address, address, address,address, address ){
        return(vendor1, vendor2, vendor3, vendor4, vendor5, vendor6);
    }

}
// File: Calibration.sol


pragma solidity ^0.8.7;



contract Calibration is Access, Database{

        function InformToVendor(uint256 _assetTag) public onlyCalibTech{
        bool present = false;
        for(uint i = 0 ; i<TMDE.length ; i++){
            if(TMDE[i].assetTag == _assetTag){
                TMDE[i].inUse = false;
                TMDE[i].due = true;
                present = true;
            }
        }
        if(present == true){
        STATE[_assetTag] = state.Informed;
        emit DueForCalibration(_assetTag);
        }
        else{
                revert("TMDE not found!");
            }
    }

        function PassCalibration(uint256 _assetTag, uint256 _certificate, uint256 _nextCalibrationDate) public onlyVendor{
        require (STATE[_assetTag] == state.Informed || STATE[_assetTag] == state.calibFailed);
        for(uint i = 0 ; i<TMDE.length ; i++){
            if(TMDE[i].assetTag == _assetTag){
                TMDE[i].inUse = true;
                TMDE[i].due = false; 
                TMDE[i].lastCalibDate = block.timestamp;
                TMDE[i].nextCalibDate = _nextCalibrationDate;
            }
        }
        STATE[_assetTag] = state.calibPassed;
        emit CalibrationPassed(_assetTag, _certificate, _nextCalibrationDate);
    }

    function CalibrationFailed(uint256 _assetTag, uint256 _invoice, uint256 _costToService) public onlyVendor{
        require (STATE[_assetTag] == state.Informed, "You have not been informed yet!");
        serCgs[_assetTag] = _costToService;
        chargesSender[_assetTag] = msg.sender;
        STATE[_assetTag] = state.calibFailed;
        emit calibrationFailed(_assetTag, _invoice, _costToService);
    }

    function ApproveInvoice(uint256 _assetTag, uint256 invoice) public payable onlyManager{
        require (STATE[_assetTag] == state.calibFailed, "Calibration did not fail!");
        require (msg.value == serCgs[_assetTag], "Check the service charges again!");
        address rec = chargesSender[_assetTag];
        payable(rec).transfer(msg.value);
        STATE[_assetTag] = state.inApproved;
        emit InvoiceApproved(_assetTag, invoice, msg.value);
    }

    function RejectInvoice(uint256 _assetTag) public onlyManager{
        require (STATE[_assetTag] == state.calibFailed, "Calibration did not fail!");
        for(uint i = 0 ; i<TMDE.length ; i++){
            if(TMDE[i].assetTag == _assetTag){
                string memory _type = TMDE[i].Type;
                address _vendorAdd = TMDE[i].vendor;
                ScrapParts.push(scrapParts(_assetTag, _type, _vendorAdd));
                delete TMDE[i] ;
            }
        }
        emit InvoiceRejected(_assetTag);
    }

}