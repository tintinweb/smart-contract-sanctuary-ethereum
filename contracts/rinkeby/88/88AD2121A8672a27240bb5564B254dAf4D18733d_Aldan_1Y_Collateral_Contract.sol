//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './BaseAldanContract.sol';
import './IAldanTypes.sol';

contract Aldan_1Y_Collateral_Contract is BaseAldanContract {

    // 1Y
    uint private _collateralDuration = 31536000;
    // 1Y
    uint private _collateralExtend = 31536000;


    /************ CONSTRUCTOR ***************************/
    constructor(string memory version) {
        _version = version;
    }

    function getCollateralDuration() public override(BaseAldanContract) view returns (uint) {
        return _collateralDuration;
    }

    function getCollateralExtend() public override(BaseAldanContract) view returns (uint)     {
        return _collateralExtend;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './IAldanTypes.sol';

abstract contract BaseAldanContract {

    /*********************** ATTRIBUTES *****************/

    //** Public **
    // current version of contract
    string public _version;
    // Deactivated contracts cant receive funds to lock
    bool _contractActive = true;

    //** Internals **

    // Storage of collaterals
    mapping(string => IAldanTypes.Fund[]) internal _myMap;

    // basic security key
    address internal _deactivationPubKey = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // Default duration of collateral Number of years : 3 * 365 days (timestamp)
    uint private _collateralDuration = 94608000;
    // Default collateral extend : 365 days (timestamp)
    uint private _collateralExtend = 31536000;

    /************************* EVENTS AND LOGS ****************/
    event LogWithKey(string key, address indexed sender, string message);


    /************************* FUNCTIONS ****************/
    //** Public **
    function lockFund(string memory _key) public payable {
        require(_contractActive);
        require(msg.value > 0);
        require(notEmptyKey(_key));

        emit LogWithKey(_key, msg.sender, "Start fund lock");

        // Get concerned contract
        IAldanTypes.Fund memory fund = getFundByContractIdAndSender(_key, msg.sender);

        // TODO : see for case of a deactivated fund ? need check for non null first

        if (fund.active) {
            emit LogWithKey(_key, msg.sender, "Active Fund found");

            // Case of multiple amount from same address
            uint fundIndex = getFundIndexByContractIdAndSender(_key, msg.sender);
            _myMap[_key][fundIndex].amount += msg.value;
        } else {
            emit LogWithKey(_key, msg.sender, "No active Fund founded");
            fund.amount = msg.value;

            // Build collateral
            fund.lockTimeStamp = block.timestamp;
            fund.active = true;
            fund.senderPubKey = msg.sender;
            fund.startDate = block.timestamp;

            // Save it in storage map
            _myMap[_key].push(fund);
        }

        emit LogWithKey(_key, msg.sender, "Fund up to date and added");

    }

    function unlockFund(string memory _key) public payable {
        require(notEmptyKey(_key));
        emit LogWithKey(_key, msg.sender, "Start fund unlock");

        IAldanTypes.Fund memory fund = getFundByContractIdAndSender(_key, msg.sender);

        require(fund.amount > 0);
        require(fund.active && checkFundDateValidity(_key, msg.sender));

        emit LogWithKey(_key, msg.sender, "Fund active and dates valid, start return trnasaction");

        // Low level call -> check for alternative and optimize Gas consumption
        (bool success, bytes memory data) = fund.senderPubKey.call{value : fund.amount, gas : 5000}(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
        );
        if (success) {
            fund.active = false;
            emit LogWithKey(_key, msg.sender, "Funds returned");
        }
    }

    function checkFund(string memory _key) public view returns (uint){
        require(checkDataAccess(_key));
        return getFundAmountByContractId(_key);
    }

    function checkFundBySender(string memory _key) public view returns (uint){
        require(checkDataAccess(_key));
        return getFundAmountByContractIdAndSender(_key, msg.sender);
    }

    function checkFundDetails(string memory _key) public pure returns (string[3] memory) {
        require(notEmptyKey(_key));

        string[3] memory details;
        details[0] = "456";
        details[1] = "123";
        details[2] = "789";


        return details;
    }

    function concat(string memory _x, string memory _y) pure internal returns (string memory) {
        bytes memory _xBytes = bytes(_x);
        bytes memory _yBytes = bytes(_y);

        string memory _tmpValue = new string(_xBytes.length + _yBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0;i<_xBytes.length;i++) {
            _newValue[j++] = _xBytes[i];
        }

        for(i=0;i<_yBytes.length;i++) {
            _newValue[j++] = _yBytes[i];
        }

        return string(_newValue);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function checkVersion() public view returns (string memory) {
        return _version;
    }

    function delayCollateralForOneYear(string memory _key) public {
        require(checkDataAccess(_key));
        emit LogWithKey(_key, msg.sender, "Start delay collateral for one year");
        IAldanTypes.Fund memory fund = getFundByContractIdAndSender(_key, msg.sender);
        fund.startDate = fund.startDate + _collateralExtend;
    }

    function deactivatedContract() public {
        require(msg.sender == _deactivationPubKey);
        emit LogWithKey("none", msg.sender, "Start contract deactivation");
        _contractActive = false;
    }

    //** Internal **
    function getCollateralDuration() virtual view public returns (uint) {
        return _collateralDuration;
    }

    function getCollateralExtend() virtual view public returns (uint) {
        return _collateralExtend;
    }

    //** Private **
    function notEmptyKey(string memory _key) private pure returns (bool) {
        bytes memory _bytesContractNumber = bytes(_key);
        return _bytesContractNumber.length > 0;
    }

    function getFundAmountByContractId(string memory _key) internal view returns (uint256) {
        require(notEmptyKey(_key));

        uint fundsAmount = 0;

        IAldanTypes.Fund[] memory funds = _myMap[_key];
        for (uint i = 0; i < funds.length; i++) {
            if (funds[i].active) {
                fundsAmount += funds[i].amount;
            }
        }

        return fundsAmount;
    }


    function getFundAmountByContractIdAndSender(string memory _key, address _sender) internal view returns (uint256) {
        require(notEmptyKey(_key));
        require(_sender != address(0));

        IAldanTypes.Fund[] memory funds = _myMap[_key];
        for (uint i = 0; i < funds.length; i++) {
            if (funds[i].senderPubKey == _sender) {
                return funds[i].amount;
            }
        }

        return 0;
    }

    function getFundByContractIdAndSender(string memory _key, address _sender) internal view returns (IAldanTypes.Fund memory) {
        require(notEmptyKey(_key));
        require(_sender != address(0));

        IAldanTypes.Fund[] memory funds = _myMap[_key];
        for (uint i = 0; i < funds.length; i++) {
            if (funds[i].senderPubKey == _sender) {
                return funds[i];
            }
        }

        // Cant return null here
        IAldanTypes.Fund memory emptyFund;
        emptyFund.active = false;
        return emptyFund;
    }

    function getFundIndexByContractIdAndSender(string memory _key, address _sender) internal view returns (uint) {
        require(notEmptyKey(_key));
        require(_sender != address(0));
        bool fundExist = false;
        uint fundIndex = 0;


        IAldanTypes.Fund[] memory funds = _myMap[_key];
        for (uint i = 0; i < funds.length; i++) {
            if (funds[i].senderPubKey == _sender) {
                fundExist = true;
                fundIndex = i;
            }
        }

        require(fundExist);

        return fundIndex;
    }

    function getFundsByContractId(string memory _key) private view returns (IAldanTypes.Fund[] memory) {
        require(notEmptyKey(_key));
        return _myMap[_key];
    }

    function checkFundDateValidity(string memory _key, address _sender) private view returns (bool) {
        return block.timestamp > getFundByContractIdAndSender(_key, _sender).startDate
        + _collateralDuration;
    }

    //https://solidity-by-example.org/function-modifier/
    function checkDataAccess(string memory _key) private view returns (bool) {

        IAldanTypes.Fund[] memory funds = getFundsByContractId(_key);
        if (funds.length < 1) {
            return false;
        }

        // Can't access if at least one Fund is inactive for contractId
        for (uint i = 0; i < funds.length; i++) {
            if (!funds[i].active) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAldanTypes {
    struct Fund {
        uint256 amount;
        uint lockTimeStamp;
        bool active;
        uint startDate;
        address senderPubKey;
    }

    struct Funds {
        Fund[] funds;
    }
}