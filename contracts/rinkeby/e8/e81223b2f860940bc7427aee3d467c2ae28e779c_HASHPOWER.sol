/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface IULTRA {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
}

interface IALPHA {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
}

interface IBETA {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
}

interface IGAMMA {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
}

interface IDELTA {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
}

/**
::::::ccclccccclloooollooodxxxxxxxxdddxxkkkkkkkkO00000000OOkkkkkkxxdddxxxxxxxdoolllooolccccccc::::::
ccccllcccccllloooollooddxxxxxxxddxxxkkkkkkkOO000000000000000OOOkkkkkkxxxxxxxxxxxddoollloollccccccc::
llcccclllooooollooddxxxxxxxxxxxxkkkkkkkOO000OOO0KKK0000KK000OOOOOOkkkkkOkkkxxxxxxxxxddoolllolllccccc
cclllooooollloodxxxxxxxxxxxkkOkkkOOO00000OkkOkOOK00kxkkkkxxkkkkkkOO0OOkkkkOOkkkxxxxxxxxxddoooloollcc
looooolllooddxxxxxxxxxkkkOOkOOO000000OkkOkkO0Oxoc,.. .';coddddxxdxkkkkOOOOkkkkOOkkxxxdxxxxxxddoollll
oooolooddxxxxxxxxxkkkkOOOOO000000OOOOOkk0Oxoc,.          .';coddddxxxxkkkkkOOOkkkkOOkkxxxddxxxxxdool
oooloxxxxxxxxxkkkkOOOO0000O000O00OkkOOxoc,.                  .';coxxdxxxxxkkkxkkOOkkkOOOkkxxddxxxxxx
oolldxxdxxkkkkkOOO000OO000O000OOOOxo:,.                          .';coxxdxkkkxkkxxkkkOkkkOOOkxddxxxx
oolldxxdxOkkkOO00OO00OOO0OOkOOxo:,.                                  .';coxxdk0K0OkxkOOOOkkkkOxdxxxx
oolldxddkOxk00O00OOOOOxxkkxl:,.                                          .';:oxkO0K0000OO00xxOxdxxxx
oolldxddkOkkO0OOOkxxkkdl:,.                                                  ..,ckKKK0KKOO0kxOxdxxxx
oocldxddkOxxkkxxxkdc:,.                                                          lkkK0KKOO0kxOxdxxxx
oollxxdxkkxxddxxkc.                                                              :dd00KKOO0kxOxdxxxx
ooloxxdxOkxxdddxk,                                                               :ddOOKKOO0kxOxdxxxx
ooloxxxxOkxxxxxxk,                                                               :ddOO00OO0kxOxdxxxx
ooldxxxxOkxkOOxxk,            ..'''.                           .',;;,.           :ddOkk0OO0kkOxdxxxx
ooldxxxxOkxkO0xxk,           'kOdodkxc.     'c.              cOOkkkko.           :ddOkk0OO0kkOkxxxxx
ooodxxdxOxkk00dxk,           :Kl   .c0d.    cXo       ::    .dWx.                :ddOkk0OO0kkOkxxxxx
olodxxdxOxkO00dxk,           :Kc    .dO.    lW0,     .OO'    lNx.                :doOkk0OO0kkOkdxxxx
olodxxdxOxkO00kkk,           ;Kk::::o0o     oWWd.    :XNl    :Xk.                :doOkk0OO0kkOkdxxxx
olldxxdxOxkO0K0KO,           ;KOcccldkkc.  .dX0O;   .xKKO'   ,KO.                :dokkk0OO0kkOxdxxxx
olldxxdxOkkOOK00k,           ;0l      ;Ok. .k0:xx.  ;0lc0l   .O0'                :dokkk0OO0kkOxdxxxx
ollxxxdxOkkOOK0Od,           ,0l       ,Oc .Ok.,k: .dO'.xO.  .xK,                :dokkx0OO0kxOxdxxxx
oclxxxdkOkkkOK0kd,           ,0o       .kl '0x. lxclOo  :Kl   dX:                :dokkxOOO0xxOxddxxx
ocoxxxdkkkOk000kd,           ,0o       :O; ,0d  .xXX0,  .kO.  lXc                :dokxxOOO0xkOxodxxx
oloxxddkkkOO00Okd,           '0x.  ..,lkc  ;0l   :OXx.   cKc  ;Kd.               :dokkOKOO0kkOxodxxx
oloxxddkkkOO0kkkd,           .lxlclool:.   ;O:   .'c;    'Ok. .d0kxdxxo.         :dokO0KOO0xkOxodxxx
lldxxdokkkOO0kxkd,                         ...            ,:.   ';cloo:.         :dokk0XOOOxxOkddxxx
lldxxddkkkO0Kxxkd,                                                               :dokO0X00OxxOkddxxx
lldxxddkxkO0Kxxxd,                                                               :dokO0X0OOxkOkddxxx
lldxxddkxkOO0kxxo,                                                               :od000XOOOxkOkddxxx
lldxxdxkxkOO0kxdo,                                                               :od0O0X0OOxkOkddxxx
loxxxdxkxkOOKkxdo,                                                              .lod00KXOOOxkOkddxxx
loxxxdxkxkO0Kkxdo,                                                          .':cdkxkK0KKOOOxkOkddxxx
loxxxdxkxOO0K00xol,..                                                   .':ldkkxxkO00000O0OxkOkddxxx
loxxxdxkkOOO000Oxxxdl:,.                                            .,:ldkkxxkOOO00000000OkkOOkddxxx
loxxxxkkkO00O0000Okkxxxxdoloc'.                                 .':ldkkxxkOOO000000000OOkkOOOkxddxxx
loxxxdxOkkkkO0000000OOkkk000Okdc;'.                         .,:ldkkxxxkOO00000000OOOOOOOOkkxxddxxxxd
llodxddxxkOkkkkkO00000000Okkkkxxxxoc;'.                 .,:ldkkxxkkkO00000000OkkkkOOOkkxxxdxxxxxdool
oollodxxxxxxkOkkxkkO0000000KKK0Okkddddoc:,.         .,:ldkkxdkOOO00000000OkkkkkOOkkxxddxxxxxddoolloo
lloooloodxxxxxxkkkkxkkO000000000000Okxddxxol:,..,:cldkkxdxkOO00000000OkkkkkOOkkxxddxxxxxdddoollooooo
ccllloooooddxxxxxxkkOkkkkO0000000000000OOOOO0KOOOOkxdxkkO0000O000OkkkkkOOkkxxxdxxxxxxddoooloooooollc
lccccllooolooddxxxxxxxkOkkkkkkkkOO00O000KKKKKKK00OOOO000000000OkkkkOOOkxxddxxxxxxddoooloooooollccccc
ccclccccloooolloodxxxxdxxkOOOOOOkkkkO00OO0000KKKKKK0000000OkkkkkOOkxxxddxxxxxddoolloooooollcccccccll
:::clllccclloooolloodxxxxxxxkkkkkOOkkkkOO00O0000000000OOkkkkOOkxxxxxxxxxxxdoollloooooollccccclclllll
:::::ccllccccllooollloddxxxxxxxxxxkkOOkkkkOO00000OOOkkkkOOkxxxddxxxxxxdooolloooooollccccccllcllllcc:
;:::;::cccllcccllooooolloddxxxxxxxxxxxkkOOkkkOOOkkkkOOkxxxddxxxxxxddoolllooooolllcccclllcclllccc::::
',;;::::::ccllcccclloooooloooddxxxxxxxxxxkkOOOOOOkkkxxddxxxxxxxdoolllooooolllccccclccllllccc::::::::
''',;;::::::cclccccccllllooollloodxxxxxxxxxxxkxxxdddxxxxxxxdoollloooooollcccccllcllcclcc::::::::::;;
''''',;:::::::cccllcccccccooooolllodxxxxxxxxxdddxxxxxxxxxdolllooooooolccccccclllllllcc:;::::::::;,,'

    Hashpower is the utility token of the BMC ecosystem. The contract is structured to passively emit 10 HASH daily to each Ultra Miner. 
    Support for four additional NFT collections to generate HASH has been included (As Alpha, Beta, Gamma, Delta) incase in the future, new collections in the ecosystem will generate HASH.

*/

contract HASHPOWER is ERC20, Ownable {
    using Address for address;

    //Epoch Unix start time for HASH rewards
    uint256 public uRewardStartDate;
    uint256 public aRewardStartDate;
    uint256 public bRewardStartDate;
    uint256 public cRewardStartDate;
    uint256 public dRewardStartDate;

    //Whether HASH rewards are active
    bool public uDailyReward = true;
    bool public aDailyReward;
    bool public bDailyReward;
    bool public cDailyReward;
    bool public dDailyReward;

    //Last Claim time for a particular tokenid
    mapping (uint256 => uint256) uLastReward;
    mapping (uint256 => uint256) aLastReward;
    mapping (uint256 => uint256) bLastReward;
    mapping (uint256 => uint256) cLastReward;
    mapping (uint256 => uint256) dLastReward;

    //Daily HASH reward
    uint256 public uRewardAmount = 10 ether;
    uint256 public aRewardAmount;
    uint256 public bRewardAmount;
    uint256 public cRewardAmount;
    uint256 public dRewardAmount;

    //NFT Addresses to generate HASH
    IULTRA public uContract;
    IALPHA public aContract;
    IBETA public bContract;
    IGAMMA public cContract;
    IDELTA public dContract;

    constructor(IULTRA _uContract) ERC20("HASHPOWER", "HASH") {
        uRewardStartDate = block.timestamp - 1 days;
        uContract = _uContract;
    }

    //A maximum of five collections can potentially generate HASH in the future.
    modifier validCollection(uint256 _collection) {
        require(_collection > 0 && _collection < 6, "Invalid input");
        _;
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "No Smart Contracts");
        _;
    }

    function checkUltraDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (uLastReward[tokenID] > uRewardStartDate) ? uLastReward[tokenID] : uRewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate)/(1 days);
        return (rewardDays*uRewardAmount);
    }

    function checkAlphaDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (aLastReward[tokenID] > aRewardStartDate) ? aLastReward[tokenID] : aRewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate)/(1 days);
        return (rewardDays*aRewardAmount);
    }

    function checkBetaDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (bLastReward[tokenID] > bRewardStartDate) ? bLastReward[tokenID] : bRewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate)/(1 days);
        return (rewardDays*bRewardAmount);
    }

    function checkGammaDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (cLastReward[tokenID] > cRewardStartDate) ? cLastReward[tokenID] : cRewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate)/(1 days);
        return (rewardDays*cRewardAmount);
    }

    function checkDeltaDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (dLastReward[tokenID] > dRewardStartDate) ? dLastReward[tokenID] : dRewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate)/(1 days);
        return (rewardDays*dRewardAmount);
    }

    function claimUltraRewards(uint256[] memory tokenIDs) public {
        require(uDailyReward,"Not Active");
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l = tokenIDs.length;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < l; i++) {
            uint256 id = tokenIDs[i];
            require(uContract.ownerOf(id) == caller, "Not Owner");
            reward = checkUltraDailyReward(id);
            if(reward > 0){
                uLastReward[id] = timestamp;
                total += reward;
            }
        }
        require(total > 0, "None to claim");
        _mint(caller, total);
    }

    function claimAlphaRewards(uint256[] memory tokenIDs) public {
        require(aDailyReward,"Not Active");
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l = tokenIDs.length;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < l; i++) {
            uint256 id = tokenIDs[i];
            require(aContract.ownerOf(id) == caller, "Not Owner");
            reward = checkAlphaDailyReward(id);
            if(reward > 0){
                aLastReward[id] = timestamp;
                total += reward;
            }
        }
        require(total > 0, "None to claim");
        _mint(caller, total);
    }

    function claimBetaRewards(uint256[] memory tokenIDs) public {
        require(bDailyReward,"Not Active");
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l = tokenIDs.length;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < l; i++) {
            uint256 id = tokenIDs[i];
            require(bContract.ownerOf(id) == caller, "Not Owner");
            reward = checkBetaDailyReward(id);
            if(reward > 0){
                bLastReward[id] = timestamp;
                total += reward;
            }
        }
        require(total > 0, "None to claim");
        _mint(caller, total);
    }

    function claimGammaRewards(uint256[] memory tokenIDs) public {
        require(cDailyReward,"Not Active");
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l = tokenIDs.length;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < l; i++) {
            uint256 id = tokenIDs[i];
            require(cContract.ownerOf(id) == caller, "Not Owner");
            reward = checkGammaDailyReward(id);
            if(reward > 0){
                cLastReward[id] = timestamp;
                total += reward;
            }
        }
        require(total > 0, "None to claim");
        _mint(caller, total);
    }

    function claimDeltaRewards(uint256[] memory tokenIDs) public {
        require(dDailyReward,"Not Active");
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l = tokenIDs.length;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < l; i++) {
            uint256 id = tokenIDs[i];
            require(dContract.ownerOf(id) == caller, "Not Owner");
            reward = checkDeltaDailyReward(id);
            if(reward > 0){
                dLastReward[id] = timestamp;
                total += reward;
            }
        }
        require(total > 0, "None to claim");
        _mint(caller, total);
    }

    function checkWalletRewards(address _address) public view returns (uint256){
        uint256 total;
        uint256 l;

        if (uDailyReward){
            uint256[] memory utokenIDs = uContract.tokensOfOwner(_address);
            l = utokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                total += checkUltraDailyReward(utokenIDs[i]);
            }
        }

        if (aDailyReward){
            uint256[] memory atokenIDs = aContract.tokensOfOwner(_address);
            l = atokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                total += checkAlphaDailyReward(atokenIDs[i]);
            }
        }

        if (bDailyReward){
            uint256[] memory btokenIDs = bContract.tokensOfOwner(_address);
            l = btokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                total += checkBetaDailyReward(btokenIDs[i]);
            }
        }

        if (cDailyReward){
            uint256[] memory ctokenIDs = cContract.tokensOfOwner(_address);
            l = ctokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                total += checkGammaDailyReward(ctokenIDs[i]);
            }
        }
        
        if (dDailyReward){
            uint256[] memory dtokenIDs = dContract.tokensOfOwner(_address);
            l = dtokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                total += checkDeltaDailyReward(dtokenIDs[i]);
            }
        }

        return total;
    }

    function claimAllRewards(uint256[] memory utokenIDs, uint256[] memory atokenIDs, uint256[] memory btokenIDs, uint256[] memory ctokenIDs, uint256[] memory dtokenIDs) public {
        address caller = _msgSender();
        require (caller == tx.origin, "No Smart Contracts");
        uint256 total;
        uint256 reward;
        uint256 l;
        uint256 id;
        uint256 timestamp = block.timestamp;

        if (uDailyReward && utokenIDs.length > 0){
            l = utokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                id = utokenIDs[i];
                require(uContract.ownerOf(id) == caller, "Not Owner");
                reward = checkUltraDailyReward(id);
                if(reward > 0){
                    uLastReward[id] = timestamp;
                    total += reward;
                }
            }
        }

        if (aDailyReward && atokenIDs.length > 0){
            l = atokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                id = atokenIDs[i];
                require(aContract.ownerOf(id) == caller, "Not Owner");
                reward = checkAlphaDailyReward(id);
                if(reward > 0){
                    aLastReward[id] = timestamp;
                    total += reward;
                }
            }
        }

        if (bDailyReward && btokenIDs.length > 0){
            l = btokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                id = btokenIDs[i];
                require(bContract.ownerOf(id) == caller, "Not Owner");
                reward = checkBetaDailyReward(id);
                if(reward > 0){
                    bLastReward[id] = timestamp;
                    total += reward;
                }
            }
        }

        if (cDailyReward && ctokenIDs.length > 0){
            l = ctokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                id = ctokenIDs[i];
                require(cContract.ownerOf(id) == caller, "Not Owner");
                reward = checkGammaDailyReward(id);
                if(reward > 0){
                    cLastReward[id] = timestamp;
                    total += reward;
                }
            }
        }

        if (dDailyReward && dtokenIDs.length > 0){
            l = dtokenIDs.length;
            for (uint256 i = 0; i < l; i++) {
                id = dtokenIDs[i];
                require(dContract.ownerOf(id) == caller, "Not Owner");
                reward = checkDeltaDailyReward(id);
                if(reward > 0){
                    dLastReward[id] = timestamp;
                    total += reward;
                }
            }
        }

        require(total > 0, "None to claim");
        _mint(caller, total);

    }

     function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        uint256 r = receivers.length;
        require(r != 0, "Zero length passed");
        require(r == amounts.length, "Different Lengths");
        for (uint256 i = 0; i < r; i++) {
            transfer(receivers[i], amounts[i]);
        }
    } 

    //This is only here if needed at a future date like the additional HASH generating contracts
    function mintHash(uint256 _amount) public onlyOwner nonContract {
        _mint(msg.sender, _amount);
    }

    function burnHash(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function rewardStatus(uint256 _collection, bool _status) public validCollection (_collection) onlyOwner {
        bool success;

        if (_collection == 1 && uRewardStartDate != 0){ 
            uDailyReward = _status;
            success = true;
            }
        if (_collection == 2 && aRewardStartDate != 0){ 
            aDailyReward = _status;
            success = true;
            }
        if (_collection == 3 && bRewardStartDate != 0){ 
            bDailyReward = _status;
            success = true;
            }
        if (_collection == 4 && cRewardStartDate != 0){ 
            cDailyReward = _status;
            success = true;
            }
        if (_collection == 5 && dRewardStartDate != 0){ 
            dDailyReward = _status;
            success = true;
            }
  
        require(success, "Epoch Date not initialized");
    }

    function setRewardsTime(uint256 _collection) public validCollection (_collection) onlyOwner {
        bool success;

        if (_collection == 1 && uContract != IULTRA(address(0))){ 
            uRewardStartDate = block.timestamp;
            success = true;
            }
        if (_collection == 2 && aContract != IALPHA(address(0))){ 
            aRewardStartDate = block.timestamp;
            success = true;
            }
        if (_collection == 3 && bContract != IBETA(address(0))){ 
            bRewardStartDate = block.timestamp;
            success = true;
            }
        if (_collection == 4 && cContract != IGAMMA(address(0))){ 
            cRewardStartDate = block.timestamp;
            success = true;
            }
        if (_collection == 5 && dContract != IDELTA(address(0))){ 
            dRewardStartDate = block.timestamp;
            success = true;
            }

        require(success, "Contract Address not initialized");
    }

    function setRewardsAmount(uint256 _collection, uint256 _amount) public validCollection (_collection) onlyOwner {
        
        if (_collection == 1){ 
            uRewardAmount = _amount;
            }
        if (_collection == 2){ 
            aRewardAmount = _amount;
            }
        if (_collection == 3){ 
            bRewardAmount = _amount;
            }
        if (_collection == 4){ 
            cRewardAmount = _amount;
            }
        if (_collection == 5){ 
            dRewardAmount = _amount;
            }
        
    }

    function setContractAddress(uint256 _collection, address _contract) public validCollection (_collection) onlyOwner {
        require(_contract != address(0), "Cannot assign Null Address");

        if (_collection == 1){ 
            uContract = IULTRA(_contract); 
            }
        if (_collection == 2){ 
            aContract = IALPHA(_contract); 
            }
        if (_collection == 3){ 
            bContract = IBETA(_contract); 
            }
        if (_collection == 4){ 
            cContract = IGAMMA(_contract); 
            }
        if (_collection == 5){ 
            dContract = IDELTA(_contract); 
            }

    }

}