pragma solidity 0.8.11;

import "./CustomERC20PresetMinterPauser.sol";

contract HPTToken is CustomERC20PresetMinterPauser {

    uint8 private _decimals = 18;
    uint256 private _maxTotalSupply = 30_000_000_000 * (10 ** _decimals);
    uint256 _initialRelease = 10_000_000_000 * (10 ** _decimals);
    uint256 _initial_bridge_Release = 500_000 * (10 ** _decimals);
    uint256 private _totalRelease = 0;

    modifier _isReleased(uint256 amount) {
        uint256 remainingTokens = totalRelease() - totalSupply();
        require(amount <= remainingTokens, "Should Release Token First");
        _;
    }

    modifier _maxTotalSupplyNotFull(uint256 amount) {
        uint256 remainingTokens = maxTotalSupply() - totalSupply();
        require(amount <= remainingTokens, "TotalSupply must less thn maxTotalSupply");
        _;
    }

    constructor(string memory _name, string memory _symbol, address  _owner, address  _handler) CustomERC20PresetMinterPauser(_name, _symbol, _owner) {
        _totalRelease += _initialRelease;
        _totalRelease += _initial_bridge_Release;
        _mint(_owner, _initialRelease);
        _setupRole(MINTER_ROLE, _handler);
    }

    function release(uint256 amount) public onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) returns (bool) {
        require((_maxTotalSupply - _totalRelease) >= amount, "Release amount out of max total supply");
        _totalRelease += amount;
        return true;
    }

    function mint(address to, uint256 amount) public override _isReleased(amount) _maxTotalSupplyNotFull(amount) {
        super.mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function maxTotalSupply() public view returns (uint256) {
        return _maxTotalSupply;
    }

    function totalRelease() public view returns (uint256) {
        return _totalRelease;
    }


    function initialRelease() public view returns (uint256) {
        return _initialRelease;
    }

}