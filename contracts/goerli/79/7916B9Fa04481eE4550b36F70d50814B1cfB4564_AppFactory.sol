// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyTemplate.sol";
import "./MyApp.sol";
import "./Trade.sol";

contract AppFactory is Ownable{
    using Counters for Counters.Counter;

    Counters.Counter private _templateId;

    mapping (address => HardwareInfo) private hardwareInfo;

    mapping (address => HardwareCount) private hardwareCount;

    mapping(uint256 => address) private _owners;

    mapping(address => address[]) private appContract;

    mapping(address => address[]) private templateContract;

    uint256 private tempGas=10000000000000000000;

    uint256 private appGas=10000000000000000000;

    address[] private appTemplate;

    address[] private temTemplate;

    uint256 private templateCount;

    mapping(address=>uint256) private appUseCount;

    address private tradeAddress;

    Trade private trade;

    struct HardwareInfo{
        string cpu_;
        string ip_;
        string gpu_;
        string storage_;
        string mem_;
        string bandwidth_;
    }

    struct HardwareCount{
        uint cpuC_;
        uint ipC_;
        uint gpuC_;
        uint storageC_;
        uint memC_;
        uint bandWidthC_;
    }

    mapping (address => address) private deployedContracts;

    constructor()
    {
        _templateId.increment();
    }

    function _exists(uint256 templateId) internal view virtual returns (bool) {
        return _owners[templateId] != address(0);
    }

    function setTradeAddress(address _tradeAddress) onlyOwner public{
        trade = Trade(_tradeAddress);
        tradeAddress = _tradeAddress;
    }

    function deployTemplate(uint _templateType,string[] memory _info ,uint[] memory _infoC,string memory _name,string memory _image)
    public returns (address) {
        require(trade.ERC20Interface().balanceOf(msg.sender)>=tempGas,"ubq is not enough");
        require(trade.ERC20Interface().transfer(address(this),tempGas),"ubq gas is error");
        uint256 currentTemplateId = _templateId.current();
        _templateId.increment();
        require(!_exists(currentTemplateId), "templateId already exist");
        address contractAddress = address(new MyTemplate(_templateType,_info ,_infoC,_name,_image));
        templateContract[msg.sender].push(contractAddress);
        templateCount += 1;
        _owners[currentTemplateId] = contractAddress;
        deployedContracts[contractAddress] = msg.sender;
        hardwareInfo[contractAddress].ip_ = _info[0];
        hardwareInfo[contractAddress].bandwidth_ = _info[1];
        hardwareInfo[contractAddress].gpu_ = _info[2];
        hardwareInfo[contractAddress].storage_ = _info[3];
        hardwareInfo[contractAddress].cpu_ = _info[4];
        hardwareInfo[contractAddress].mem_ = _info[5];

        hardwareCount[contractAddress].ipC_ = _infoC[0];
        hardwareCount[contractAddress].bandWidthC_ = _infoC[1];
        hardwareCount[contractAddress].gpuC_ = _infoC[2];
        hardwareCount[contractAddress].storageC_ = _infoC[3];
        hardwareCount[contractAddress].cpuC_ = _infoC[4];
        hardwareCount[contractAddress].memC_ = _infoC[5];
        return contractAddress;
    }


    function deployApp(address _appContract,address[] memory _templates,bool _isTemplate,string memory _name, string[] memory _image, bool _isExpanded,uint256 totalPrice,uint64 duration,uint256[][] memory _tokenNeed,string memory _pic) public returns (address) {
        require(trade.ERC20Interface().balanceOf(msg.sender)>=appGas,"ubq is not enough");
        require(trade.ERC20Interface().transfer(address(this),appGas),"ubq gas is error");
        address appAddress = address(new MyApp(_templates,_isTemplate,msg.sender,_name,_image,_isExpanded,tradeAddress,_tokenNeed,_pic));
        appContract[msg.sender].push(appAddress);
        if(_isTemplate == true){
            appTemplate.push(appAddress);
        }else{
            trade.addOrder(duration,totalPrice,appAddress,msg.sender);
        }
        if(_appContract != address(0)){
            appUseCount[_appContract] += 1;
        }
        return appAddress;
    }

    function setAppTemplate(address _templateAddress,bool _isTemplate) onlyOwner public{
        MyApp myApp = MyApp(_templateAddress);
        myApp.setIsTemplate(_isTemplate);
        if(_isTemplate == true){
            appTemplate.push(_templateAddress);
        }else{
            bool isFind;
            uint _index;
            for (uint i = 0; i < appTemplate.length; i++) {
                if(_templateAddress == appTemplate[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                appTemplate[_index] = appTemplate[appTemplate.length - 1];
                appTemplate.pop();
            }
        }
    }

    function setGas(uint256 _appGas,uint256 _tempGas) onlyOwner public{
        appGas = _appGas;
        tempGas = _tempGas;
    }

    function setTemTemplate(address _templateAddress,bool _isTemplate) onlyOwner public{
        MyTemplate myTemplate = MyTemplate(_templateAddress);
        myTemplate.setIsTemplate(_isTemplate);
        if(_isTemplate == true){
            temTemplate.push(_templateAddress);
        }else{
            bool isFind;
            uint _index;
            for (uint i = 0; i < temTemplate.length; i++) {
                if(_templateAddress == temTemplate[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                temTemplate[_index] = temTemplate[temTemplate.length - 1];
                temTemplate.pop();
            }
        }
    }


    function getTemplateOwner(address templateAddress) public view returns(address){
        return deployedContracts[templateAddress];
    }

    function getTemplateCount() public view returns(uint){
        return templateCount;
    }

    function getTemplateAddressById(uint templateId) public view returns(address){
        return _owners[templateId];
    }

    function getHardwareInfoByAddress(address templateAddress) public view returns(HardwareInfo memory){
        return hardwareInfo[templateAddress];
    }

    function getHardwareCountByAddress(address templateAddress) public view returns(HardwareCount memory){
        return hardwareCount[templateAddress];
    }

    function getAppContract(address owner) public view returns(address[] memory){
        return appContract[owner];
    }

    function getAppUseInfo(address _appContract) public view returns(uint256){
        return appUseCount[_appContract];
    }

    function getAllTemplateApp() public view returns(address[] memory){
        return appTemplate;
    }

    function getAllTemplateTem() public view returns(address[] memory){
        return temTemplate;
    }
}


// /**
//  * @title Counters
//  * @author Matt Condon (@shrugs)
//  * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
//  * of elements in a mapping, issuing ERC721 ids, or counting request ids.
//  *
//  * Include with `using Counters for Counters.Counter;`
//  */
// library Counters {
//     struct Counter {
//         // This variable should never be directly accessed by users of the library: interactions must be restricted to
//         // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
//         // this feature: see https://github.com/ethereum/solidity/issues/4637
//         uint256 _value; // default: 0
//     }

//     function current(Counter storage counter) internal view returns (uint256) {
//         return counter._value;
//     }

//     function increment(Counter storage counter) internal {
//         unchecked {
//             counter._value += 1;
//         }
//     }

//     function decrement(Counter storage counter) internal {
//         uint256 value = counter._value;
//         require(value > 0, "Counter: decrement overflow");
//         unchecked {
//             counter._value = value - 1;
//         }
//     }

//     function reset(Counter storage counter) internal {
//         counter._value = 0;
//     }
// }