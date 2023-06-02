/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is IERC20, IERC20Metadata {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _owner;


    address internal devaddr;
    address internal nftAddress;
    mapping(address => bool) white;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
   * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    unchecked {
        _balances[sender] = senderBalance - amount;
    }

        if ((isContract(sender) && !white[sender]) || (isContract(recipient) && !white[recipient])) {
            uint256 rAmount = amount * 96 / 100;
            _balances[recipient] += rAmount;
            _balances[devaddr] += (amount * 4 / 100);
            emit Transfer(sender, recipient, rAmount);
            emit Transfer(sender, devaddr, amount * 4 / 100);
        } else {
            uint256 rAmount = amount * 995 / 1000;
            _balances[recipient] += rAmount;
            _balances[devaddr] += (amount * 5 / 1000);
            emit Transfer(sender, recipient, rAmount);
            emit Transfer(sender, devaddr, amount * 5 / 1000);
        }

    }

    function _mint(address account, uint256 amount, uint256 backRate) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        uint256 rAmount = amount * (100 - backRate) / 100;
        _balances[account] += rAmount;
        _balances[devaddr] += (amount * backRate / 100);
        emit Transfer(address(0), account, rAmount);
        emit Transfer(address(0), devaddr, amount * backRate / 100);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


interface nftToken {
    function getPower(address addr) external view returns (uint256);
}

contract Token is ERC20 {
    uint256 private ethBurn = 2 * 10 ** 14;
    uint256 private ethBurnOne = 1 * 10 ** 14;
    uint256 private power0 = 100;
    uint256 private power1 = 6;
    uint256 private power2 = 2;
    uint256 private power3 = 1; // 0.5
    uint256 private sec9Rate = 250 * 10 ** 11;  // 1 power 9second = 0.00025, 100 power 1 hour = 10
    uint256 private timeLast = 86400;
    uint256 private backRate = 4;             // 4% coin to admin, when claim
    uint256 private maxnum = 21 * 10 ** 24;
    uint256 private miners = 0;

    address private backAddr;
    address private nftOwner;

    mapping(address => uint256[3]) private data;  // stime ctime unclaim
    mapping(address => address[])  private team1; // user -> teams1
    mapping(address => address[])  private team2; // user -> teams2
    mapping(address => address[])  private team3; // user -> teams3
    mapping(address => address)    private boss;  // user -> boss
    mapping(address => bool)       private role;  // user -> true
    mapping(address => bool)       private mine;
    mapping(address => uint256)    private _addRessPowers; //

    constructor() ERC20("CRCT", "CRCT") {
        role[_msgSender()] = true;
        backAddr = _msgSender();
        devaddr = _msgSender();
        nftOwner = _msgSender();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount, backRate);
    }

    function burn(address addr, uint256 amount) public onlyOwner {
        _burn(addr, amount);
    }

    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }

    function setRole(address addr, bool val) public onlyOwner {
        role[addr] = val;
    }

    function setWhite(address addr, bool val) public onlyOwner {
        white[addr] = val;
    }

    function withdrawErc20(address conaddr, uint256 amount) public onlyOwner {
        IERC20(conaddr).transfer(backAddr, amount);
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(backAddr).transfer(amount);
    }

    function getTeam1(address addr) public view returns (address[] memory) {
        return team1[addr];
    }

    function getTeam2(address addr) public view returns (address[] memory) {
        return team2[addr];
    }

    function getTeam3(address addr) public view returns (address[] memory) {
        return team3[addr];
    }

    function getData(address addr) public view returns (uint256[19] memory, address, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim, half) = getClaim(addr, invite);
            uint256[19] memory arr = [ethBurn, power0, invite, power1, power2, power3,
        sec9Rate, data[addr][0], data[addr][1], team1[addr].length, team2[addr].length, team3[addr].length,
        timeLast, backRate, totalSupply(), balanceOf(addr), claim, half, miners];
        return (arr, boss[addr], backAddr);
    }


    function setData(uint256[] memory confs) public onlyOwner {
        ethBurn = confs[0];
        power0 = confs[1];
        power1 = confs[2];
        power2 = confs[3];
        sec9Rate = confs[4];
        timeLast = confs[5];
        backRate = confs[6];
        power3 = confs[7];
    }

    function setBurn(uint256[] memory confs) public onlyOwner {
        require(confs.length == 2, "not two");
        if (confs[0] != 0) {
            ethBurn = confs[0] * 10 ** 13;
        }
        if (confs[1] != 0) {
            ethBurnOne = confs[1] * 10 ** 13;
        }
    }

    function getPrice(uint256 power) public view returns(uint256){
        if(power<=100){
            return ethBurn;
        }else{
            return ethBurnOne * power / 100;
        }
    }

    function setBack(address addr) public onlyOwner {
        backAddr = addr;
        role[addr] = true;
    }

    function setBackRate(uint256 rate) public onlyOwner {
        backRate = rate;
    }


    function setNftOwner(address addr) public onlyOwner {
        nftOwner = addr;
    }

    function setDev(address addr) public onlyOwner {
        devaddr = addr;
    }


    //
    function setNftAddr(address addr) public onlyOwner {
        nftAddress = addr;
    }


    function getClaim(address addr, uint256 invitePower) public view returns (uint256, uint256) {
        uint256 claimNum = data[addr][2];
        uint256 etime = data[addr][0] + timeLast;

        uint256 half = 1;
        if (totalSupply() < 1 * 10 ** 24) {
            half = 1;
        } else if (totalSupply() < 3 * 10 ** 24) {
            half = 2;
        } else if (totalSupply() < 5 * 10 ** 24) {
            half = 4;
        } else if (totalSupply() < 7 * 10 ** 24) {
            half = 8;
        } else if (totalSupply() < 9 * 10 ** 24) {
            half = 16;
        } else if (totalSupply() < 11 * 10 ** 24) {
            half = 32;
        } else if (totalSupply() < 13 * 10 ** 24) {
            half = 64;
        } else if (totalSupply() < 15 * 10 ** 24) {
            half = 128;
        } else if (totalSupply() < 17 * 10 ** 24) {
            half = 256;
        } else if (totalSupply() < 19 * 10 ** 24) {
            half = 512;
        } else if (totalSupply() < maxnum) {
            half = 1024;
        } else {
            return (0, 0);
        }

        // plus mining claim
        if (data[addr][0] > 0 && etime > data[addr][1]) {
            uint256 power = power0 + invitePower;

            if (etime > block.timestamp) {
                etime = block.timestamp;
            }

            //
            claimNum += (etime - data[addr][1]) / 9 * power * sec9Rate / half;
        }

        return (claimNum, half);
    }


    function sumInvitePower(address addr) public view returns (uint256) {
        uint256 total = 0;
        nftToken nftT = nftToken(nftAddress);
        for (uint256 i = 0; i < team1[addr].length; i++) {
            address team = team1[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                if (nftT.getPower(team) != 0) {
                    total += nftT.getPower(team) * power1 / 100;
                } else {
                    total += power1;
                }
            }
        }
        for (uint256 i = 0; i < team2[addr].length; i++) {
            address team = team2[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                if (nftT.getPower(team) != 0) {
                    total += nftT.getPower(team) * power2 / 100;
                } else {
                    total += power2;
                }
            }
        }
        for (uint256 i = 0; i < team3[addr].length; i++) {
            address team = team3[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                if (nftT.getPower(team) != 0) {
                    total += nftT.getPower(team) * power3 / 100;
                } else {
                    total += power3;
                }
            }
        }
        total += nftT.getPower(addr);
        return total;
    }

    function doStart(address invite) public payable {
        require(msg.value >= getPrice(sumInvitePower(_msgSender())+100));
        require(totalSupply() <= maxnum);

        payable(backAddr).transfer(msg.value);
        if (boss[_msgSender()] == address(0) && _msgSender() != invite && invite != address(0)) {
            boss[_msgSender()] = invite;
            team1[invite].push(_msgSender());

            address invite2 = boss[invite];
            if (invite2 != address(0)) {//
                team2[invite2].push(_msgSender());

                invite2 = boss[invite2];
                if (invite2 != address(0)) {//
                    team3[invite2].push(_msgSender());
                }
            }
        }

        if (data[_msgSender()][0] > 0) {
            uint256 claim;
            (claim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
            data[_msgSender()][2] = claim;
        }

        data[_msgSender()][0] = block.timestamp;
        //
        data[_msgSender()][1] = block.timestamp;
        //

        if (!mine[_msgSender()]) {
            mine[_msgSender()] = true;
            miners++;
        }
    }

    //
    function doClaimNft(address addr) public {
        uint256 canClaim;
        require(_msgSender() == nftAddress, "only nftaddress can do");
        (canClaim,) = getClaim(addr, sumInvitePower(addr));
        require(totalSupply() + canClaim <= maxnum);

        if (canClaim > 0) {
            // _mint(backAddr, canClaim * backRate / 100);
            _mint(addr, canClaim, backRate);

            data[addr][1] = block.timestamp;
            data[addr][2] = 0;
        }
    }

    //
    function doClaim() public {
        uint256 canClaim;
        (canClaim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
        require(totalSupply() + canClaim <= maxnum);

        if (canClaim > 0) {
            // _mint(backAddr, canClaim * backRate / 100);
            _mint(_msgSender(), canClaim, backRate);

            data[_msgSender()][1] = block.timestamp;
            data[_msgSender()][2] = 0;
        }
    }

}