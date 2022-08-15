// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface CarbonCoinI {
    function isAddressInBlackList (address) external view returns (bool);
    function balanceOf (address) external view returns (uint);
    function transfer (address, uint) external returns (bool);
    function redeemDebit (address, uint) external returns (bool);
}

interface CarbonCoinProxyI {
    function listCert (uint) external view returns (uint256, address, uint, uint, uint256);
    function getCertIndex() external view returns (uint);
}

contract CarbonCoinProxy {
    address private _owner;
    address private _admin;
    address private _gcxTokenAddress;
    address private exchangeCollector;
    address private exchangeFeeCollector;
    address private redeemCollector;
    address private redeemFeeCollector;
    uint public exchangeFee;
    uint private redeemFee;
    IERC20 public exchangeableToken;
    uint public certIndex;
    uint private exchangeRate;
    bool private allowExchange;
    uint public _totalSupply;
    CarbonCoinI private gcxToken;
    //CarbonCoinProxyI private previousCarbonCoinProxy;

    struct Cert{
        uint256 fullName;
        address recipient;
        uint datetime;
        uint quantity; 
        uint256 email;
    }

    Cert[] public cert;
    
    constructor(address gcxTokenAddress, address gcxRateUpdateAddress) {
        //exchangeableToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        exchangeableToken = IERC20(0xE912639B6Ea8C2EFaAC9c47A4CF4d510e508368B);
        allowExchange = true;
        exchangeRate = 48010500;
        certIndex = 0;
        _owner = msg.sender;
        _admin = gcxRateUpdateAddress;
        _gcxTokenAddress = gcxTokenAddress;
        gcxToken = CarbonCoinI(gcxTokenAddress);
        exchangeFee = 100;
        redeemFee = 1000000000000000;
        exchangeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        exchangeFeeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        redeemCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        redeemFeeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        //previousCarbonCoinProxy = CarbonCoinProxyI(0x1E0FACc2e7AeE4e79B4cCe2e32Ca18021678be29);
    }    

    function name() public view virtual returns (string memory) {
        return "Green Carbon Proxy";
    }

    function symbol() public view virtual returns (string memory) {
        return "GCXProxy";
    }

    function exchangeToken (uint amountInGCX) external returns (bool) {
        require(1 <= amountInGCX, 'Invalid amount');
        require(allowExchange, 'Service unavailable');
        require(!gcxToken.isAddressInBlackList(msg.sender), 'Address is in Black List');
        uint amountInUSDT = amountInGCX * exchangeRate;
        amountInUSDT = amountInUSDT / 1000000;
        uint fee = 0;
        if (exchangeFee > 0) {
            fee = amountInUSDT / exchangeFee;
        }
        require(amountInUSDT + fee <= exchangeableToken.balanceOf(msg.sender), 'Insufficient token');
        require(gcxToken.balanceOf(address(this)) >= amountInGCX, 'Insufficient balance');
        exchangeableToken.transferFrom(msg.sender, exchangeCollector, amountInUSDT);
        if (fee > 0) {
            exchangeableToken.transferFrom(msg.sender, exchangeFeeCollector, fee);
        }
        gcxToken.transfer(msg.sender, amountInGCX);
        return true;
    }

    function redeem (uint256 fullName, uint quantity, uint256 email) external payable returns (uint) {
        require(gcxToken.balanceOf(msg.sender) >= quantity, 'Insufficient balance');
        require(msg.value == redeemFee, 'Insufficient to cover fees');
        payable(redeemFeeCollector).transfer(redeemFee);
        Cert memory userCert = Cert(fullName, msg.sender, block.timestamp, quantity, email);
        cert.push(userCert);
        certIndex += 1;
        gcxToken.redeemDebit(msg.sender, quantity);
        gcxToken.transfer(redeemCollector, quantity);
        return quantity;
    }

    function updateExchangeRate (uint rate) external {
        require(msg.sender == _admin || msg.sender == _owner);
        require(rate > 0);
        exchangeRate = rate;
    }

    function transferToken (address token, uint amount) external {
        require(msg.sender == _owner);
        require(amount > 0);
        IERC20 tokenContract = IERC20(token);
        tokenContract.transfer(_owner, amount);        
    }
    
    function updateOwner (address newOwner) external {
        require(msg.sender == _owner);
        _owner = newOwner;
    }
    
    function updateAdmin (address newAdmin) external {
        require(msg.sender == _owner);
        _admin = newAdmin;
    }

    function updateExchangeTokenAllow (bool allow) external {
        require(msg.sender == _owner);
        allowExchange = allow;
    }

    function updateExchangeTokenAddress (address newAddress) external {
        require(msg.sender == _owner);
        exchangeableToken = IERC20(newAddress);
    }
    
    function updateExchangeFee(uint fee) external {
        require(msg.sender == _owner);
        exchangeFee = fee;
    }
    
    function updateRedeemFee(uint fee) external {
        require(msg.sender == _owner);
        redeemFee = fee;
    }
    
    function updateExchangeCollector(address collector) external {
        require(msg.sender == _owner);
        exchangeCollector = collector;
    }
    
    function updateExchangeFeeCollector(address collector) external {
        require(msg.sender == _owner);
        exchangeFeeCollector = collector;
    }
    
    function updateRedeemFeeCollector(address collector) external {
        require(msg.sender == _owner);
        redeemFeeCollector = collector;
    }

    function updateRedeemCollector(address collector) external {
        require(msg.sender == _owner);
        redeemCollector = collector;
    }

    function getExchangeRate() public view returns (uint) {
        return exchangeRate;
    }

    function listCert (uint index) public view returns(uint256, address, uint, uint, uint256) {
        //uint previousIndex = previousCarbonCoinProxy.getCertIndex();
        //require(index < previousIndex + certIndex);
        //if (index < previousIndex) {
        //    return previousCarbonCoinProxy.listCert(index);
        //} else {
        //    uint currentIndex = index - previousIndex;
        //    return (cert[currentIndex].fullName, cert[currentIndex].recipient, cert[currentIndex].datetime ,cert[currentIndex].quantity, cert[currentIndex].email);
        //}
        return (cert[index].fullName, cert[index].recipient, cert[index].datetime ,cert[index].quantity, cert[index].email);
    }

    function getCertIndex() public view returns (uint) {
        //uint previousIndex = previousCarbonCoinProxy.getCertIndex();
        //return previousIndex + certIndex;
        return certIndex;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function getAdmin() public view returns (address) {
        return _admin;
    }
    
    function getExchangeTokenAllow() public view returns (bool) {
        return allowExchange;
    }
    
    function getExchangeTokenAddress() public view returns (address) {
        return address(exchangeableToken);
    }
    
    function getExchangeFee() public view returns (uint) {
        return exchangeFee;
    }
    
    function getRedeemFee() public view returns (uint) {
        return redeemFee;
    }
    
    function getExchangeCollector() public view returns (address) {
        return exchangeCollector;
    }
    
    function getExchangeFeeCollector() public view returns (address) {
        return exchangeFeeCollector;
    }
    
    function getRedeemCollector() public view returns (address) {
        return redeemCollector;
    }

    function getRedeemFeeCollector() public view returns (address) {
        return redeemFeeCollector;
    }
}