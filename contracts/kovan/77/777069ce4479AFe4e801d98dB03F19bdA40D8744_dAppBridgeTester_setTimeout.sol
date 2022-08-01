pragma solidity ^0.4.16;

import "github.com/dAppBridge/dAppBridge-Client/dAppBridge-Client_Kovan.sol";

//
// Simple contract which does something every 240 seconds
// Using the dAppBridge.com service
// Start by calling startTesting
// Contract will then run itself every 240 seconds
//

contract dAppBridgeTester_setTimeout is clientOfdAppBridge {
    
    int public callback_times = 0;

    // Contract Setup
    address public owner;
    function dAppBridgeTester_setTimeout() payable {
        owner = msg.sender;
    }
    function kill() public {
      if(msg.sender == owner) selfdestruct(owner);
    }
    //
    
    // The key returned here can be matched up to the original response below
    function callback(bytes32 key) external payable only_dAppBridge{
        // Do somethiing here - your code...
        callback_times++;

        // If we want to continue running, call setTimeout again...
        bytes32 newkey = setTimeout("callback", 240);
    }
    

    function startTesting() public {
        if(msg.sender == owner)
            bytes32 newkey = setTimeout("callback", 0);
    }
}

pragma solidity ^0.4.16;

interface dAppBridge_I {
    function getOwner() external returns(address);
    function getMinReward(string requestType) external returns(uint256);
    function getMinGas() external returns(uint256);    
    function setTimeout(string callback_method, uint32 timeout) external payable returns(bytes32);
    function setURLTimeout(string callback_method, uint32 timeout, string external_url, string external_params, string json_extract_element) external payable returns(bytes32);
    function callURL(string callback_method, string external_url, string external_params, string json_extract_element) external payable returns(bytes32);
    function randomNumber(string callback_method, int32 min_val, int32 max_val, uint32 timeout) external payable returns(bytes32);
    function randomString(string callback_method, uint8 number_of_bytes, uint32 timeout) external payable returns(bytes32);
}
contract DappBridgeLocator_I {
    function currentLocation() public returns(address);
}

contract clientOfdAppBridge {
    address internal _dAppBridgeLocator_Rinkeby_addr = 0x00;
    address internal _dAppBridgeLocator_Ropsten_addr = 0x00;
    address internal _dAppBridgeLocator_Kovan_addr = 0xF96772C64965C3a2185DC9DC84F24134740Ff715;
    address internal _dAppBridgeLocator_Prod_addr = 0x00;
    
    DappBridgeLocator_I internal dAppBridgeLocator;
    dAppBridge_I internal dAppBridge; 
    uint256 internal current_gas = 0;
    uint256 internal user_callback_gas = 0;
    
    function initBridge() internal {
        //} != _dAppBridgeLocator_addr){
        if(address(dAppBridgeLocator) != _dAppBridgeLocator_Kovan_addr){ 
            dAppBridgeLocator = DappBridgeLocator_I(_dAppBridgeLocator_Kovan_addr);
        }
        
        if(address(dAppBridge) != dAppBridgeLocator.currentLocation()){
            dAppBridge = dAppBridge_I(dAppBridgeLocator.currentLocation());
        }
        if(current_gas == 0) {
            current_gas = dAppBridge.getMinGas();
        }
    }

    modifier dAppBridgeClient {
        initBridge();

        _;
    }
    

    event event_senderAddress(
        address senderAddress
    );
    
    event evnt_dAdppBridge_location(
        address theLocation
    );
    
    event only_dAppBridgeCheck(
        address senderAddress,
        address checkAddress
    );
    
    modifier only_dAppBridge_ {
        initBridge();
        
        //emit event_senderAddress(msg.sender);
        //emit evnt_dAdppBridge_location(address(dAppBridge));
        emit only_dAppBridgeCheck(msg.sender, address(dAppBridge));
        require(msg.sender == address(dAppBridge));
        _;
    }

    // Ensures that only the dAppBridge system can call the function
    modifier only_dAppBridge {
        initBridge();
        address _dAppBridgeOwner = dAppBridge.getOwner();
        require(msg.sender == _dAppBridgeOwner);

        _;
    }
    

    
    function setGas(uint256 new_gas) internal {
        require(new_gas > 0);
        current_gas = new_gas;
    }

    function setCallbackGas(uint256 new_callback_gas) internal {
        require(new_callback_gas > 0);
        user_callback_gas = new_callback_gas;
    }

    

    function setTimeout(string callback_method, uint32 timeout) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('setTimeout')+user_callback_gas;
        return dAppBridge.setTimeout.value(_reward).gas(current_gas)(callback_method, timeout);

    }
    function setURLTimeout(string callback_method, uint32 timeout, string external_url, string external_params) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('setURLTimeout')+user_callback_gas;
        return dAppBridge.setURLTimeout.value(_reward).gas(current_gas)(callback_method, timeout, external_url, external_params, "");

    }
    function setURLTimeout(string callback_method, uint32 timeout, string external_url, string external_params, string json_extract_element) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('setURLTimeout')+user_callback_gas;
        return dAppBridge.setURLTimeout.value(_reward).gas(current_gas)(callback_method, timeout, external_url, external_params, json_extract_element);
    }
    function callURL(string callback_method, string external_url, string external_params) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('callURL')+user_callback_gas;
        return dAppBridge.callURL.value(_reward).gas(current_gas)(callback_method, external_url, external_params, "");
    }
    function callURL(string callback_method, string external_url, string external_params, string json_extract_elemen) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('callURL')+user_callback_gas;
        return dAppBridge.callURL.value(_reward).gas(current_gas)(callback_method, external_url, external_params, json_extract_elemen);
    }
    function randomNumber(string callback_method, int32 min_val, int32 max_val, uint32 timeout) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('randomNumber')+user_callback_gas;
        return dAppBridge.randomNumber.value(_reward).gas(current_gas)(callback_method, min_val, max_val, timeout);
    }
    function randomString(string callback_method, uint8 number_of_bytes, uint32 timeout) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward('randomString')+user_callback_gas;
        return dAppBridge.randomString.value(_reward).gas(current_gas)(callback_method, number_of_bytes, timeout);
    }
    

    // Helper internal functions
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function char(byte b) internal pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    
    function bytes32string(bytes32 b32) internal pure returns (string out) {
        bytes memory s = new bytes(64);
        for (uint8 i = 0; i < 32; i++) {
            byte b = byte(b32[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[i*2] = char(hi);
            s[i*2+1] = char(lo);            
        }
        out = string(s);
    }

    function compareStrings (string a, string b) internal pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
    
    function concatStrings(string _a, string _b) internal pure returns (string){
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory length_ab = new string(bytes_a.length + bytes_b.length);
        bytes memory bytes_c = bytes(length_ab);
        uint k = 0;
        for (uint i = 0; i < bytes_a.length; i++) bytes_c[k++] = bytes_a[i];
        for (i = 0; i < bytes_b.length; i++) bytes_c[k++] = bytes_b[i];
        return string(bytes_c);
    }
}