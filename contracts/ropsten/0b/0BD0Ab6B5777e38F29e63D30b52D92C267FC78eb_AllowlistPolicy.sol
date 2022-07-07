//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./Policy.sol";

contract AllowlistPolicy is Policy {
    /**
     * Constructor.
     * @param _cnsControllerAddress The address of the CNS Controller
     */
    constructor(address _cnsControllerAddress)
        Policy(_cnsControllerAddress, "Allowlist Policy")
    {}

    struct allowlist {
        address account;
        uint256 quota;
    }

    mapping(string => allowlist[]) public allowlists;

    /**
     * Function: addAllowlist [public].
     * @param _domain The domain
     * @param _account The account to add.
     */
    function addAllowlist(string memory _domain, address _account)
        public
        isRegisterPolicy(_domain)
        onlyOwner(_domain)
    {
        require(_account != address(0), "Account isn't valid");
        _safeAddAllowlist(_domain, _account);
    }

    function getDomainOwner(string memory _domain)
        public
        view
        returns (address)
    {
        return domains[_domain].owner;
    }

    /**
     * Function: addAllowlist [internal].
     * @param _domain The domain
     * @param _accounts The list of accounts to add.
     */
    function addMultipleAllowlist(
        string memory _domain,
        address[] memory _accounts
    ) public isRegisterPolicy(_domain) onlyOwner(_domain) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _safeAddAllowlist(_domain, _accounts[i]);
        }
    }

    /**
     * Function: addAllowlist [internal].
     * @param _domain The domain
     * @param _account The account to add.
     */

    function _safeAddAllowlist(string memory _domain, address _account)
        internal
    {
        // Fix quota to mint subdomain is 1
        allowlists[_domain].push(allowlist(_account, 1));
    }

    /**
     * Function: removeAllowlist [public].
     * @param _domain The domain
     * @param _account The account to remove.
     */
    function removeAllowlist(string memory _domain, address _account)
        public
        onlyOwner(_domain)
        isRegisterPolicy(_domain)
    {
        _safeRemoveAllowlist(_domain, _account);
    }

    /**
     * Function: _safeRemoveAllowlist [internal].
     * @param _domain The domain
     * @param _account The account to remove.
     */
    function _safeRemoveAllowlist(string memory _domain, address _account)
        internal
    {
        require(_account != address(0), "Invalid address");
        for (uint256 i = 0; i < allowlists[_domain].length; i++) {
            if (allowlists[_domain][i].account == _account) {
                delete allowlists[_domain][i];
                break;
            }
        }
    }

    /**
     * Function: getAllowlistByDomain [public].
     * @param _domain The domain
     */
    function getAllowlistByDomain(string memory _domain)
        public
        view
        returns (allowlist[] memory)
    {
        return allowlists[_domain];
    }

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     * @param _account The account to check.
     */
    function permissionCheck(string memory _domain, address _account)
        public
        view
        virtual
        override
        returns (bool)
    {
        bool _permission = false;

        for (uint256 i = 0; i < allowlists[_domain].length; i++) {
            if (
                allowlists[_domain][i].account == _account &&
                allowlists[_domain][i].quota > 0
            ) {
                _permission = true;
                break;
            }
        }

        return _permission;
    }

    function unRegisterPolicy(string memory _domain)
        public
        virtual
        override
        onlyCNSController
    {
        delete allowlists[_domain];
        _unRegisterPolicy(_domain);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";

contract Policy {
    /**
     * Constructor.
     * @param _cnsControllerAddress The address of the CNS Controller
     */
    constructor(address _cnsControllerAddress, string memory _policyName) {
        cns = ICNSController(_cnsControllerAddress);
        _name = _policyName;
    }

    /** Base Domain Structure to Register Policy */
    struct domain {
        address owner;
        string domain;
    }

    ICNSController public cns;
    mapping(string => domain) public domains;
    string private _name;

    /**
     * Modifier: onlyOwner.
     * @param _domain The domain to check.
     */
    modifier onlyOwner(string memory _domain) {
        require(domains[_domain].owner == msg.sender);
        _;
    }

    /**
     * Modifier: isRegisterPolicy.
     * @param _domain The domain to check.
     */
    modifier isRegisterPolicy(string memory _domain) {
        require(domains[_domain].owner != address(0));
        _;
    }

    modifier onlyCNSController() {
        require(msg.sender == address(cns));
        _;
    }

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     */
    function isRegister(string memory _domain) public view returns (bool) {
        return domains[_domain].owner != address(0);
    }

    /**
     * Function: registerPolicy [public].
     * @param _domain The domain
     */
    function registerPolicy(string memory _domain, address _owner) public {
        require(
            cns.isDomainRegister(_domain),
            "Domain is not registered to CNSController"
        );
        require(
            domains[_domain].owner != _owner,
            "Domain is already registered"
        );
        _registerPolicy(_domain, _owner);
    }

    /**
     * Function: registerPolicy [internal].
     * @param _domain The domain
     */
    function _registerPolicy(string memory _domain, address _owner) internal {
        domains[_domain].owner = _owner;
        domains[_domain].domain = _domain;
    }

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     * @param _account The account to check.
     */
    function permissionCheck(string memory _domain, address _account)
        public
        view
        virtual
        returns (bool)
    {
        require(_account != address(0), "Account isn't valid");
        require(
            keccak256(abi.encodePacked(_domain)) != keccak256(""),
            "Domain isn't valid"
        );
        revert("Permission Check function is not implemented for this policy");
    }

    /**
     * Function: unRegisterPolicy [public].
     * @param _domain The domain
     */
    function unRegisterPolicy(string memory _domain)
        public
        virtual
        onlyCNSController
    {
        _unRegisterPolicy(_domain);
    }

    /**
     * Function: _unRegisterPolicy [internal].
     * @param _domain The domain
     */
    function _unRegisterPolicy(string memory _domain) internal {
        delete domains[_domain];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

/**
 * @dev Interface of the CNS Controller.
 */
interface ICNSController {
    function isDomainRegister(string memory _domain)
        external
        view
        returns (bool);
}