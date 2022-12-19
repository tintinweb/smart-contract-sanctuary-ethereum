/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IPROXY_REGISTRY {
    function proxies(address _addr) external view returns (address);
}

interface ICDP_MANAGER {
    function count(address _addr) external view returns (uint256);
    function first(address _addr) external view returns (uint256);
    function list(uint256 _cdpId) external view returns (uint256, uint256);
    function ilks(uint256 _cdpId) external view returns (bytes32);
    function urns(uint256 _cdpId) external view returns (address);
}

interface IMCD_VAT {
    function urns(bytes32 _ilks, address _urnsAddr) external view returns (uint256, uint256);
    function ilks(bytes32 _ilks) external view returns (uint256, uint256, uint256, uint256, uint256);
}

interface IMCD_SPOT {
    function ilks(bytes32 _ilks) external view returns (address, uint256);
}

interface IMCD_JUG {
    function ilks(bytes32 _ilks) external view returns (uint256, uint256);
    function base() external view returns (uint256);
}

interface IPIP {
    function peek() external view returns (bytes32, bool);
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract LockValue is Initializable,Ownable{
    uint256 constant public ONE = 10 ** 27;
    IPROXY_REGISTRY public PROXY_REGISTRY;
    ICDP_MANAGER public CDP_MANAGER;
    IMCD_VAT public MCD_VAT;
    IMCD_SPOT public MCD_SPOT;
    IMCD_JUG public MCD_JUG;

    function init(
        address _PROXY_REGISTRY,
        address _CDP_MANAGER,
        address _MCD_VAT,
        address _MCD_SPOT,
        address _MCD_JUG
    ) external initializer{
        __Ownable_init_unchained();
        __LockValue_init_unchained(_PROXY_REGISTRY, _CDP_MANAGER, _MCD_VAT, _MCD_SPOT, _MCD_JUG);
    }
    
    function __LockValue_init_unchained(
        address _PROXY_REGISTRY,
        address _CDP_MANAGER,
        address _MCD_VAT,
        address _MCD_SPOT,
        address _MCD_JUG
    ) internal initializer{
        PROXY_REGISTRY = IPROXY_REGISTRY(_PROXY_REGISTRY);
        CDP_MANAGER = ICDP_MANAGER(_CDP_MANAGER);
        MCD_VAT = IMCD_VAT(_MCD_VAT);
        MCD_SPOT = IMCD_SPOT(_MCD_SPOT);
        MCD_JUG = IMCD_JUG(_MCD_JUG);
    }

    receive() payable external{

    }

    function queryValue(
        address _addr, 
        uint256 _page, 
        uint256 _limit
    ) 
        external 
        view 
        returns (uint256, uint256, uint256)
    {
        address _proxyAddr = PROXY_REGISTRY.proxies(_addr);
        if(_proxyAddr == address(0x00))return (0, 0, 0);
        uint256 _num = CDP_MANAGER.count(_proxyAddr);
        if(_num == 0)return (0, 0, 0);
        if (_limit > _num){
            _limit = _num;
        }
        if (_page<2){
            _page = 1;
        }
        _page--;
        uint256 start = _page * _limit;
        uint256 end = start + _limit;
        if (end > _num){
            end = _num;
            _limit = end - start;
        }
        uint256[] memory cdpIds = new uint256[](_limit);
        if (_num > 0){
            uint256 j;
            uint256 _firstCDPId = CDP_MANAGER.first(_proxyAddr);
            if(start == 0)cdpIds[j++] = _firstCDPId;
            for (uint256 i = 1; i < _num; i++) {
                (,uint256 _next) = CDP_MANAGER.list(_firstCDPId);
                _firstCDPId = _next;
                if(i >= start && i < end){
                    cdpIds[j++] = _next;
                }
            }
        }
        (uint256 value, uint256 debit) = getValue(cdpIds);
        return (value, debit, _num);
    }
    
    function getValue(uint256[] memory cdpIds) public view returns(uint256, uint256){
        uint256 amount;
        uint256 debit;
        uint256 cdpId;
        address urns;
        bytes32 ilks;
        uint256 ink;
        uint256 art;
        address pip;
        for (uint256 i = 0; i < cdpIds.length; i++) {
            cdpId = cdpIds[i];
            urns = CDP_MANAGER.urns(cdpId);
            ilks = CDP_MANAGER.ilks(cdpId);
            (ink, art) = MCD_VAT.urns(ilks, urns);
            if(ink > 0){
                (pip,) = MCD_SPOT.ilks(ilks);
                (bytes32 val,)= IPIP(pip).peek();
                amount += uint256(val);
                debit += getDebit(ilks, art);
            }
        }
        return (amount, debit);
    }

    function queryArt(uint256[] memory cdpIds) external view returns(uint256[] memory){
        bytes32 ilks;
        uint256 cdpId;
        address urns;
        uint256 art;
        uint256[] memory arts = new uint256[](cdpIds.length);
        for (uint256 i = 0; i < cdpIds.length; i++) {
            cdpId = cdpIds[i];
            urns = CDP_MANAGER.urns(cdpId);
            ilks = CDP_MANAGER.ilks(cdpId);
            (, art) = MCD_VAT.urns(ilks, urns);
            arts[i] = getDebit(ilks, art);
        }
        return (arts);
    }

    function getDebit(bytes32 ilk, uint256 art) internal view returns(uint256){
        (, uint256 prev,,,) = MCD_VAT.ilks(ilk);
        (uint256 duty, uint256 rho) = MCD_JUG.ilks(ilk);
        uint256 rate = rmul(rpow(add(MCD_JUG.base(), duty), block.timestamp - rho, ONE), prev);
        uint256 debit  = rmul(art, rate);
        return (debit);
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "add-overflow");
    }
    
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x, "Jug/mul-overflow");
        z = z / ONE;
    }

    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
}