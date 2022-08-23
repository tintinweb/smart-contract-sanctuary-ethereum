//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./Policy.sol";

contract AllowlistPolicy is Policy {
    constructor(address _CNSControlerAddr) Policy(_CNSControlerAddr) {
        require(_CNSControlerAddr != address(0), "Invalid address");
    }

    mapping(bytes32 => address[]) public allowList;
    mapping(bytes32 => address) internal historyMints;

    function addAllowlist(
        bytes32 _node,
        address _allowAddress
    ) public {
        require(
            Policy.isDomainOwner(_node, msg.sender),
            "Only owner can add Allowlist"
        );
        _addAllowlist(_node, _allowAddress);
    }

    function addMultiAllowlist (
        bytes32 _node,
        address[] memory _allowAddress
    ) public {
        require(
            Policy.isDomainOwner(_node, msg.sender),
            "Only owner can add Allowlist"
        );
        for(uint256 i = 0; i < _allowAddress.length;) {
            _addAllowlist(_node, _allowAddress[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _addAllowlist(bytes32 _node, address _allowAddress) internal {
        allowList[_node].push(_allowAddress);
    }

    function removeAllowlist(
        bytes32 _node,
        address _allowAddress
    ) public {
        require(
            Policy.isDomainOwner(_node, msg.sender),
            "Only owner can remove Allowlist"
        );
        _removeAllowlist(_node, _allowAddress);
    }

    function _removeAllowlist(bytes32 _node, address _allowAddress) internal {
       for (uint i = 0; i < allowList[_node].length;) {
            if (allowList[_node][i] == _allowAddress) {
                delete allowList[_node][i];
            } 
                unchecked {
                    ++i;
            }
        }
    }

    function permissionCheck(bytes32 _node, address _account)
        public
        view
        virtual
        returns (bool)
    {
      for (uint i = 0; i < allowList[_node].length;) {
            if (allowList[_node][i] == _account) {
                return true;
            } 
                unchecked {
                    ++i;
                }
        }
        return false;
    }   

    function isMint(bytes32 _node, address _account)
        internal
        view
        returns (bool)
    {
        return historyMints[_node] == _account;
    }

    function getAllowlist(bytes32 _node)
        internal
        view
        returns (address[] memory)
    {
        return allowList[_node];
    }

    function registerSubdomain(
        string calldata _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode) public {
        require(permissionCheck(_node, msg.sender), "Permission denied");
        require(isMint(_node, msg.sender), "Already minted");
        Policy.registerSubdomain(_subdomainLabel, _node, _subnode, msg.sender);
        historyMints[_node] = msg.sender;
        }
    
    function unRegisterDomain(
        bytes32 _node,
        bool _wipe
    ) public override {
        delete allowList[_node];
        delete historyMints[_node];
        if (_wipe) {
            Policy.unRegisterDomain(_node , _wipe);
        } else {
            Policy.unRegisterDomain(_node , _wipe);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";

contract Policy {
    ICNSController public cnsController;

    constructor(address _ICNSController) {
        cnsController = ICNSController(_ICNSController);
    }

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId
    ) public virtual {
        require(
            cnsController.isDomainOwner(_node, msg.sender),
            "Only owner can unregister domain"
        );
        cnsController.registerDomain(_name, _node, _tokenId, address(this));
    }

    function isDomainOwner(bytes32 _node, address _account) public view returns (bool) {
        return cnsController.isDomainOwner(_node, _account);
    }

    function unRegisterDomain(bytes32 _node, bool _wipe) public virtual {
        require(
            cnsController.isDomainOwner(_node, msg.sender),
            "Only owner can unregister domain"
        );
        if (_wipe) {
            cnsController.unRegisterDomain(_node);
        } else {
            cnsController.unRegisterDomain(_node);
        }
    }

    function registerSubdomain(
        string calldata _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) public virtual {
        cnsController.registerSubdomain(_subDomainLabel, _node, _subnode, _owner);
    }

    function unRegisterSubdomain(bytes32 _subnode) public virtual {
        cnsController.unRegisterSubdomain(_subnode);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface ICNSController {
    function isRegister(bytes32 _node) external view returns (bool);

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId,
        address _policy
    ) external;

    function registerSubdomain(
        string calldata _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) external;

    function getDomain(bytes32)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            address
        );

    function isDomainOwner(bytes32 _node, address _account)
        external
        view
        returns (bool);

    function unRegisterDomain(bytes32 _node) external;

    function unRegisterSubdomain(bytes32 _subnode) external;

    function unRegisterSubdomainAndBurn(bytes32 _subnode) external;
}