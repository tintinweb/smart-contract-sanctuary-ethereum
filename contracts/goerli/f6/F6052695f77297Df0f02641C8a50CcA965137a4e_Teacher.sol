// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface Iscore {
    function jilu(address, uint256) external;
    function cxfs(address) external returns (uint256);
}

contract Teacher {
    address public owner;
    address public Score;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        chuangjian();
    }

    function chuangjian() private {
        score _Score = new score();
        Score = address(_Score);
    }

    function szfs(address _xuesheng, uint256 _fenshu) public onlyOwner {
        require(_fenshu <= 100, " not 100 fen");
        Iscore(Score).jilu(_xuesheng, _fenshu);
    }

    function cxfs(address _xuesheng) public returns (uint256) {
        return Iscore(Score).cxfs(_xuesheng);
    }
}

contract score {
    address public owner;
    mapping(address => uint256) public fenshu;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function jilu(address _xuesheng, uint256 _fenshu) external onlyOwner {
        fenshu[_xuesheng] = _fenshu;
    }

    function cxfs(address _xuesheng) external returns (uint256) {
        return fenshu[_xuesheng];
    }
}