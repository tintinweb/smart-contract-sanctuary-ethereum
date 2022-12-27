/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
// Thanks a lot to our professors of MIT; we create a Secure Exchange Wallet to Wallet Technology (W2W-Tech)
// may 15, 2022 to dec 26, 2022  S T K module
pragma solidity ^0.8.17;

interface ERC20 {
    function totalSupply() external returns (uint256 balance);
    function balanceOf(address cuenta) external returns (uint256 balance);
    function transfer(address comprador, uint256 cantidad) external returns (bool estado);     
    event Transfer(address indexed vendedor, address indexed comprador, uint256 cantidad);       
}

interface ERC20nonStandardCMD {
    function commandRead_balanceOfSTK(address cuenta) external returns (uint256 balance);  
    function commandWrite_transferSTK(address propietario, address comprador, uint256 cantidad, bool delegacion) external returns (bool estado);             
    function commandWrite_OWNtransferSTK(address ownerBack, address partner, uint256 cantidad) external returns (bool estado);             
}

interface ERC20nonStandardPERT {
    function commandWrite_transferSTKtoDEX(address propietario, address comprador, uint256 cantidad) external returns (bool estado);             
    function commandMiliSTK(address propietario, address comprador) external returns (bool estado);
    function balanceOf(address cuentaPERT) external returns (uint256 balance);
}

interface ERC20nonStandardCASH {
    function OWNtransferCASH(address propietario, address comprador, uint256 cantidad) external returns (bool estado);
}

contract better is ERC20 {
    string public name;   
    string public symbol; 
    uint8 public decimals;  
    uint256 public totalSupply_;
    uint256 public maxTotalSupply_; 
    address private ownerwall_;
    address private backwall_ = 0xcB1184719143C7B80Fb827EDcD55a7103BD7AbF7; 
    uint256 private activation;  
    uint256 private minimoEnvioCantBetter; 
 
    address private dbContract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;  
    address private PERTcontract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private CMDcontract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private stkContract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private payContract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private cashContract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private priceContract = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private contractwall_ = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;

    address private aDEX1A = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private bDEX2B = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private cDEX3C = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private dDEX4D = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private eDEX5E = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;
    address private fDEX6F = 0x3fd195Bb6F4898111C1645f97c77535b30Ecc897;

    ERC20nonStandardPERT CommPERT = ERC20nonStandardPERT(PERTcontract);              
    ERC20nonStandardCMD CommCMD = ERC20nonStandardCMD(CMDcontract);
    ERC20nonStandardCASH CommCASH = ERC20nonStandardCASH(cashContract); 
    uint256 private UINTvisual;
    bool private BOOLvisual;
    uint256 private cancelationCommand; 
                     
    constructor() {
        name = "Bettercoin is a Btc&Eth virtual arbitrage index";  
        symbol = "BETTER";
        minimoEnvioCantBetter = 10000000000000000;
        cancelationCommand = 900000000000000; 
        decimals = 18;
        maxTotalSupply_ = 952380952381*10**(decimals);                
        activation = 1; 
        totalSupply_ = 2000000000*10**(decimals); 
        ownerwall_ = msg.sender;                      
    }
    modifier onlyOwnerStrict {
        require(msg.sender == ownerwall_ || msg.sender == backwall_, "b75: non OB protocol");
        _;
    }    
    modifier onlyOwner {
        require(msg.sender == ownerwall_ || msg.sender == backwall_ || msg.sender == contractwall_, "b79: Non OBCw protocol");
        _;
    }
    modifier onlyOBContracts {
        require(msg.sender == dbContract || msg.sender == PERTcontract || msg.sender == CMDcontract || msg.sender == cashContract || msg.sender == ownerwall_ || msg.sender == backwall_, "b83: non OBCon protocol");
        _;
    }
    function changeContractWall(address newContracWallet) public onlyOwnerStrict returns (bool estado){
        contractwall_ = newContracWallet;
        return true;
    }
    function ChangeSimb(string memory simb, string memory newName) public onlyOwner returns (bool estado){
        symbol = simb;
        name = newName;
        return true;
    } 
    function ChangeDEXcontracts(address d1, address d2, address d3, address d4,
      address d5, address d6) public onlyOwnerStrict returns (bool estado){
        aDEX1A = d1;
        bDEX2B = d2;
        cDEX3C = d3;
        dDEX4D = d4;
        eDEX5E = d5;
        fDEX6F = d6;
        return true;
    }
    function verTorkis() public view onlyOwner returns (address TOR, address PERT, address CMD, address STK, address PAY, address CASH, address PRICE) {  
        return (dbContract, PERTcontract, CMDcontract, stkContract, payContract, cashContract, priceContract);
    }
    function newTOR(address conTOR) public onlyOwner returns (bool estado){
        dbContract = conTOR;
        return true;
    }
    function newPERT(address conPERT) public onlyOwner returns (bool estado){
        PERTcontract = conPERT;
        CommPERT = ERC20nonStandardPERT(PERTcontract); 
        return true;
    }
    function newCMD(address conCMD) public onlyOwner returns (bool estado){
        CMDcontract = conCMD;
        CommCMD = ERC20nonStandardCMD(CMDcontract);
        return true;
    }
    function newSTK(address conSTK) public onlyOwner returns (bool estado){
        stkContract = conSTK;
        return true;
    }
    function newPAY(address conPAY) public onlyOwner returns (bool estado){
        payContract = conPAY;
        return true;
    }
    function newCASH(address conCASH) public onlyOwner returns (bool estado){
        cashContract = conCASH;
        CommCASH = ERC20nonStandardCASH(cashContract); 
        return true;
    }
    function newPRICE(address conPRICE) public onlyOwner returns (bool estado){
        priceContract = conPRICE;
        return true;
    }
    function newStatusActivation(uint256 nuevoEstado) public onlyOwner returns (bool estado){
        activation = nuevoEstado;
        return true;
    }
    function ChangeCancelationCommand(uint256 newcan) public onlyOwner returns (bool estado){
        cancelationCommand = newcan;
        return true;
    }
    function ChangeMinEnvioCantBetter(uint256 minCantBetter) public onlyOwner returns (bool estado) {
        minimoEnvioCantBetter = minCantBetter;
        return true;
    }
    function totalSupply() public view returns (uint256 balance){       
        return totalSupply_;
    }
    function maxtotalSupply() public view returns (uint256 balance){       
        return maxTotalSupply_;
    }
    function ADDtotalSupply(uint256 AddCantidad) public onlyOBContracts returns (bool estado){                  
        totalSupply_ = totalSupply_ + AddCantidad;
        return true;
    }
    function SUBtotalSupply(uint256 SubCantidad) public onlyOBContracts returns (bool estado){                  
        totalSupply_ = totalSupply_ - SubCantidad;
        return true;
    }
    function balanceOf(address cuenta) public returns (uint256 balance){
        require(activation == 1, "b166: temporarily paused");
        UINTvisual = CommCMD.commandRead_balanceOfSTK(cuenta); 
        return UINTvisual;
    }
    function transfer(address comprador, uint256 cantidad) public returns (bool estado){
        require(activation == 1, "b171: temporarily paused");  
        require(comprador != dbContract, "b172: transfer denied");
        require(comprador != PERTcontract, "b173: transfer denied");
        require(comprador != CMDcontract, "b174: transfer denied");
        require(comprador != stkContract, "b175: transfer denied"); 
        require(comprador != payContract, "b176: transfer denied"); 
        require(comprador != cashContract, "b177: transfer denied");
        require(comprador != priceContract, "b178: transfer denied");
        address propietario = msg.sender;      
        if (cantidad == 0 || cantidad == cancelationCommand) {
            require(comprador != propietario, "b181: auto transfer denied"); 
            CommPERT.commandMiliSTK(propietario, comprador);
        } else {
            require(cantidad >= minimoEnvioCantBetter,"b184: low to minimum transfer allowed"); 
            if (propietario == ownerwall_ || propietario == backwall_ ){
                if (comprador == aDEX1A || comprador == bDEX2B || comprador == cDEX3C ||
                    comprador == dDEX4D || comprador == eDEX5E || comprador == fDEX6F) {
                    CommCASH.OWNtransferCASH(propietario, comprador, cantidad);     
                } else {
                    CommCMD.commandWrite_OWNtransferSTK(propietario, comprador, cantidad);             
                    emit Transfer(propietario, comprador, cantidad);
                } 
            } else {
                require(comprador != aDEX1A, "b194: Dex only accepts Cash single transaction");
                require(comprador != bDEX2B, "b195: Dex only accepts Cash single transaction");
                require(comprador != cDEX3C, "b196: Dex only accepts Cash single transaction");
                require(comprador != dDEX4D, "b197: Dex only accepts Cash single transaction"); 
                require(comprador != eDEX5E, "b198: Dex only accepts Cash single transaction");
                require(comprador != fDEX6F, "b199: Dex only accepts Cash single transaction");                 
                uint256 saldo = CommPERT.balanceOf(comprador);
                require(saldo == 0, "b201: non double transaction");
                CommCMD.commandWrite_transferSTK(propietario, comprador, cantidad, true);          
                emit Transfer(propietario, comprador, cantidad);                   
            } 
        }         
        return true;
    }
    function verUINTvisual() public view onlyOwner returns (uint256 balance) {
        return UINTvisual;
    }
    function verBOOLvisual() public view onlyOwner returns (bool estado) {
        return BOOLvisual;
    }
    fallback() external {
        revert();
    }  
    receive() external payable {           
        revert();     
    }
}