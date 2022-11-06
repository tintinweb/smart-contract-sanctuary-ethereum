// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17 <0.9.0;

import "./console.sol";

contract AccessControlRules {
    uint public ACRULE_NOT_INTERNAL = 0;
    uint public ACRULE_HAS_ETH = 1;
    uint public ACRULE_HAS_ERC20 = 2;
    uint public ACRULE_HAS_NFT = 3;
    uint public ACRULE_HAS_NFT_ATTRS = 4;
    uint[] public internalACRules = [
        ACRULE_HAS_ETH,
        ACRULE_HAS_ERC20,
        ACRULE_HAS_NFT,
        ACRULE_HAS_NFT_ATTRS
    ];

    struct ACRule {
        uint rule;
        string ruleName;
        address contractAddress;
        string functionName;
        bool isActive;
    }

    mapping(string => ACRule) public acrules;
    string[] public acruleNames;

    constructor() {
        console.log("constructor called");

        for (uint i = 0; i < internalACRules.length; i++) {
            addNewRule(internalACRules[i]);
        }
    }

    function isRuleExist(string memory ruleName) public view returns (bool) {
        return bytes(acrules[ruleName].ruleName).length > 0;
    }

    function addNewRule(uint rule) public {
        address contractAddress = address(this);

        string memory ruleName;
        string memory funcName;

        if (rule == ACRULE_HAS_ETH) {
            ruleName = "hasEth";
            funcName = "hasEth(address,uint256,uint256)";
        } else if (rule == ACRULE_HAS_ERC20) {
            ruleName = "hasErc20";
            funcName = "hasErc20(address,address,uint256,uint256)";
        } else if (rule == ACRULE_HAS_NFT) {
            ruleName = "hasNft";
            funcName = "hasNft(address,address,uint256,uint256)";
        } else if (rule == ACRULE_HAS_NFT_ATTRS) {
            ruleName = "hasNftAttrs";
            funcName = "hasNftAttrs(address,address,uint256,uint256)";
        } else {
            require(false, "Cannot recognize internal rule");
        }

        ACRule memory newRule = ACRule({
            rule: rule,
            ruleName: ruleName,
            contractAddress: contractAddress,
            functionName: funcName,
            isActive: true
        });
        acrules[ruleName] = newRule;
        acruleNames.push(ruleName);
    }

    function addNewRule(
        string memory ruleName,
        address contractAddress,
        string memory functionName
    ) public {
        console.log("Add New Rule", ruleName, contractAddress, functionName);

        if (isRuleExist(ruleName)) {
            require(false, "rule already exists");
        }

        ACRule memory newRule = ACRule({
            rule: ACRULE_NOT_INTERNAL,
            ruleName: ruleName,
            contractAddress: contractAddress,
            functionName: functionName,
            isActive: true
        });
        acrules[ruleName] = newRule;
        acruleNames.push(ruleName);
    }

    function deleteRule(string memory ruleName) public {
        console.log("Delete Rule", ruleName);

        delete acrules[ruleName];

        // find the index of the rule name and remove it from the array
        uint ruleIdx = 0;
        for (uint i = 0; i < acruleNames.length; i++) {
            if (
                keccak256(abi.encodePacked(acruleNames[i])) ==
                keccak256(abi.encodePacked(ruleName))
            ) {
                ruleIdx = i;
                break;
            }
        }

        // remove the rule name in the array
        for (uint i = ruleIdx; i < acruleNames.length - 1; i++) {
            acruleNames[i] = acruleNames[i + 1];
        }
        acruleNames.pop();
    }

    function deactivateRule(string memory ruleName) public {
        console.log("Deactivate Rule", ruleName);

        acrules[ruleName].isActive = false;
    }

    function getRule(string memory ruleName)
        public
        view
        returns (
            string memory,
            address,
            string memory,
            bool
        )
    {
        console.log("Get Rule", ruleName);

        ACRule memory rule = acrules[ruleName];
        return (
            rule.ruleName,
            rule.contractAddress,
            rule.functionName,
            rule.isActive
        );
    }

    function isRuleActive(string memory ruleName) public view returns (bool) {
        console.log("Get Rule", ruleName);

        ACRule memory rule = acrules[ruleName];
        return rule.isActive;
    }

    function hasEth(
        address walletAddr,
        uint256 min,
        uint256 max
    ) public view returns (uint256) {
        console.log("hasEth");
        console.log(walletAddr);
        console.log("++++++++++");
        console.log(walletAddr.balance);
        console.log("========");

        if (walletAddr.balance < min) {
            return 0;
        }

        if (walletAddr.balance > max) {
            return 0;
        }

        return 1;
    }

    function hasErc20(
        address walletAddr,
        address erc20Contract,
        uint256 min,
        uint256 max
    ) public view returns (uint256) {
        console.log("hasErc20");
        console.log(walletAddr);

        (bool isCalled, bytes memory abiData) = erc20Contract.staticcall(
            abi.encodeWithSignature("balanceOf(address)", walletAddr)
        );
        require(isCalled, "fail to check balance of ERC20");

        uint256 balance = abi.decode(abiData, (uint256));
        console.log(balance);

        if (balance < min) {
            return 0;
        }

        if (balance > max) {
            return 0;
        }

        return 1;
    }

    function hasNft(
        address walletAddr,
        address nftContract,
        uint256 min,
        uint256 max
    ) public view returns (uint256) {
        console.log("hasErc20");
        console.log(walletAddr);

        (bool isCalled, bytes memory abiData) = nftContract.staticcall(
            abi.encodeWithSignature("balanceOf(address)", walletAddr)
        );
        require(isCalled, "fail to check balance of NFT");

        uint256 balance = abi.decode(abiData, (uint256));
        console.log(balance);

        if (balance < min) {
            return 0;
        }

        if (balance > max) {
            return 0;
        }

        return 1;
    }

    function isWalletValidInRule(ACRule memory acrule, bytes memory funcData)
        public
        view
        returns (uint256 resp)
    {
        console.log("isWalletValidInRule");
        console.log(acrule.ruleName);
        console.log(acrule.functionName);

        (bool success, bytes memory data) = acrule.contractAddress.staticcall(
            funcData
        );
        console.log(success);
        resp = abi.decode(data, (uint256));
        console.log(resp);

        require(
            success,
            string.concat("fail to call function", acrule.functionName)
        );

        return resp;
    }

    function isWalletValidInRule(
        string memory ruleName,
        address walletAddress,
        uint256 arg1,
        uint256 arg2
    ) external view returns (uint) {
        console.log("isWalletValidInRule4");
        console.log(walletAddress.balance);

        ACRule memory acrule = acrules[ruleName];
        if (acrule.rule == ACRULE_HAS_ETH) {
            console.log(walletAddress);
            console.log(walletAddress.balance);
            console.log("++++++++++");
            return hasEth(walletAddress, arg1, arg2);
        }

        return
            isWalletValidInRule(
                acrule,
                abi.encodeWithSignature(
                    acrule.functionName,
                    walletAddress,
                    arg1,
                    arg2
                )
            );
    }

    function isWalletValidInRule(
        string memory ruleName,
        address walletAddress,
        address arg1,
        uint256 arg2,
        uint256 arg3
    ) public view returns (uint) {
        console.log("isWalletValidInRule5");

        ACRule memory acrule = acrules[ruleName];
        if (acrule.rule == ACRULE_HAS_ERC20) {
            return hasErc20(walletAddress, arg1, arg2, arg3);
        } else if (acrule.rule == ACRULE_HAS_NFT) {
            return hasNft(walletAddress, arg1, arg2, arg3);
        }

        return
            isWalletValidInRule(
                acrules[ruleName],
                abi.encodeWithSignature(
                    acrule.functionName,
                    walletAddress,
                    arg1,
                    arg2,
                    arg3
                )
            );
    }

    /*
    function isWalletValidInRule(string memory ruleName, address walletAddress)
        public
        returns (uint)
    {
        console.log(
            "Check the user wallet address is valid for access control rules",
            walletAddress,
            ruleName
        );

        ACRule memory acrule = acrules[ruleName];
        (bool success, bytes memory data) = acrule.contractAddress.delegatecall(
            abi.encodeWithSignature(acrule.functionName, walletAddress)
        );
        console.log(success);
        console.log(string(data));
        console.log(string(abi.encodePacked(data)));
        console.log(uint256(bytes32(data)));

        require(
            success,
            string.concat("fail to call function", acrule.functionName)
        );
        return uint256(bytes32(data));
    }

    function isWalletValidInRules(
        string[] memory ruleNames,
        address walletAddress
    ) public returns (uint) {
        uint resultValue = 0; // Fail to validate
        for (uint i = 0; i < ruleNames.length; i++) {
            resultValue = isWalletValidInRule(ruleNames[i], walletAddress);
            console.log(resultValue);
            if (resultValue == 0) {
                console.log("Fail to validate");
                break;
            }
        }
        return resultValue;
    }
    */
}