/*
簡單說明一下，在「GameSystem」中導入了會員系統，會員可以在「GameSystem」中進行召集賽局、參與賽局。
 */
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;
/* (0-1)庫 import */
// 導入自訂套件
import "./CMemberSystem.sol";

contract CGameSystem is CMemberSystem {
    /* (0-1)庫 import */
    /* (0-1)介面 interface */
    /* (1-1)資料結構：枚舉 enum */
    /* (1-2)資料結構：結構 struct */
    /* (2)裝飾器 modifier */
    /* (3)事件 event */
    /* (4)常數、變數、陣列(array)、映射(mapping) */
    /* (5)建構子 constructor */
    /* (6)函數 function*/

    /* (1-2)資料結構：結構 struct */
    // 玩家（地址、是否為召集人）
    struct Player {
        address playerAddress;
        bool isInitiator;
    }
    // 召集（Id、召集人、日期、開始時間、結束時間、規模、玩家列表、候補列表、狀態）
    struct Recruit {
        uint256 recruitId;
        address host;
        uint256 date;
        StartTime startTime;
        EndTime endTime;
        GameScale scale;
        Player[] players;
        Player[] extraPlayers;
        GameStatus status;
    }
    // 賽局：Id、玩家列表、日期、開始時間、結束時間、規模、狀態
    struct Game {
        uint256 gameId;
        Player[] players;
        uint256 date;
        StartTime startTime;
        EndTime endTime;
        GameScale scale;
        GameStatus status;
    }

    /* (2)裝飾器 modifier */
    // 裝飾器：賽局召集中限定
    modifier onlyGameRecruited(uint256 _recruitId) {
        require(
            idToRecruits[_recruitId].status == GameStatus.RECRUITED,
            "=== onlyGameRecruited NOT PASS ==="
        );
        _;
    }
    // 裝飾器：場主限定
    modifier onlyHost() {
        require(HOST_ADDRESS == msg.sender, "=== onlyHost NOT PASS ===");
        _;
    }
    // 裝飾器：賽局審核中限定
    modifier onlyGameAuditing(uint256 _gameId) {
        require(
            idToGames[_gameId].status == GameStatus.AUDITING,
            "=== onlyGameAuditing NOT PASS ==="
        );
        _;
    }
    // 裝飾器：有召集中賽局
    modifier hasRecruitedGame() {
        require(recruits.length > 0, "=== hasRecruitedGame NOT PASS ===");
        _;
    }
    // 裝飾器：自己不在指定的召集會員陣列中
    modifier notInThisRecruit(uint256 _recruitId) {
        Player[] memory players = idToRecruits[_recruitId].players;
        for (uint256 i = 0; i < players.length; i++) {
            require(
                players[i].playerAddress != msg.sender,
                "=== notInRecruitPlayers NOT PASS ==="
            );
        }
        _;
    }
    // 裝飾器：還有候補名額
    modifier hasExtraQuota(uint256 _recruitId) {
        require(
            idToRecruits[_recruitId].extraPlayers.length <
                EXTRA_PLAYERS_LIMITED,
            "=== hasExtraPlayer NOT PASS ==="
        );
        _;
    }

    /* (4)常數、變數、陣列(array)、映射(mapping) */
    // 玩家陣列
    // Player[] internal playersInGame;
    // 玩家映射
    // mapping(uint256 => Player[]) internal addressToPlayersInGame;
    // 召集id(初始值為1)
    uint256 internal recruitId = 1;
    // 賽局id(初始值為1)
    uint256 internal gameId = 1;
    // 召集陣列
    Recruit[] internal recruits;
    // 召集映射(以召集id為索引)
    mapping(uint256 => Recruit) internal idToRecruits;
    // 賽局陣列
    Game[] internal games;
    // 賽局映射(以賽局id為索引)
    mapping(uint256 => Game) internal idToGames;
    // 人數限制：可申請加入的人數限制(含場主)
    uint256 internal PLAYERS_LIMITED = 4;
    // 人數限制：候補人數限制
    uint256 internal EXTRA_PLAYERS_LIMITED = 1;

    /* (5)建構子 constructor */
    constructor() {}

    /* (6)函數 function*/

    // 函數(6-1)：發起賽局、召集賽局(日期、開始時間、結束時間、規模)(會員限定)
    function recruitGame(
        uint256 _date,
        StartTime _startTime,
        EndTime _endTime,
        GameScale _scale
    ) public onlyMember {
        // 建立召集（Id、召集人、日期、開始時間、結束時間、規模、玩家列表、候補列表、狀態）
        // 這裡要用「storage」，因為後面要使用「push」添加玩家後，再加入陣列
        // 而「memory」是不可「push」的，所以要用「storage」
        // (我猜想)若改為「memory」，需加入陣列後，再透過「index」修改陣列中的「Players」陣列
        Recruit storage _recruit = idToRecruits[recruitId];
        // 設定召集id
        _recruit.recruitId = recruitId;
        // 設定召集人
        _recruit.host = msg.sender;
        // 設定日期
        _recruit.date = _date;
        // 設定開始時間
        _recruit.startTime = _startTime;
        // 設定結束時間
        _recruit.endTime = _endTime;
        // 設定規模
        _recruit.scale = _scale;
        // 加入玩家（發起人）
        _recruit.players.push(Player(msg.sender, true));
        // 假如不是場主，將場主加入玩家陣列
        if (msg.sender != HOST_ADDRESS)
            _recruit.players.push(Player(HOST_ADDRESS, false));
        // 設定狀態
        _recruit.status = GameStatus.RECRUITED;
        // 將召集加入召集陣列
        recruits.push(_recruit);
        // 建立召集之後 id+1
        recruitId++;
    }

    // 函數：加入召集(輸入一個召集id)(會員限定、召集中限定、自己不在此召集中)
    function joinRecruitedGame(uint256 _recruitId)
        public
        onlyMember
        onlyGameRecruited(_recruitId)
        notInThisRecruit(_recruitId)
    {
        // 玩家加入召集映射
        idToRecruits[_recruitId].players.push(Player(msg.sender, false));
        // 加入後 -> 檢查是否滿額（不用保留給場主）
        // 因為在建立召集時已經檢查，若發起人不是主時就加入了
        // 假如滿額，狀態改為「審核中」
        if (idToRecruits[_recruitId].players.length == (PLAYERS_LIMITED)) {
            // 滿額後狀態改變為「審核中」
            idToRecruits[_recruitId].status = GameStatus.AUDITING;
            // 啟動候補機制
        }
        // 函數最後要替換召集陣列
        recruits[_recruitId - 1] = idToRecruits[_recruitId];
    }

    // 函數：加入候補名單(輸入一個召集id)(會員限定、自己不在此召集中、審核中限定、還有候補名額)
    function joinExtraPlayerList(uint256 _recruitId)
        public
        onlyMember
        notInThisRecruit(_recruitId)
        onlyGameAuditing(_recruitId)
        hasExtraQuota(_recruitId)
    {
        // 加入候補
        idToRecruits[_recruitId].extraPlayers.push(Player(msg.sender, false));
        // 加入後 -> 檢查候補是否滿額
        if (
            idToRecruits[_recruitId].extraPlayers.length ==
            EXTRA_PLAYERS_LIMITED
        ) {
            // 滿額後若有程序要處理，再加入
        }
        // 函數最後要替換召集陣列
        recruits[_recruitId - 1] = idToRecruits[_recruitId];
    }

    // 函數：建立賽局(場主限定、賽局審核中限定)(召集id、日期、開始時間、結束時間、規模)
    // 傳入參數（召集id）用以指定要建立的賽局是哪個召集
    function createGame(uint256 _recruitId)
        public
        onlyHost
        onlyGameAuditing(_recruitId)
    {
        // 從映射(mapping)取得空賽局
        Game storage _game = idToGames[gameId];
        // 從映射取得已建立且審核中的召集
        Recruit storage _recruit = idToRecruits[_recruitId];
        // 全球唯一賽局id
        _game.gameId = gameId;
        // 日期、開始時間、結束時間、規模
        _game.date = _recruit.date;
        _game.startTime = _recruit.startTime;
        _game.endTime = _recruit.endTime;
        _game.scale = _recruit.scale;
        /* 這裡我暫時不處理候補程序，確認程序無誤再來處理候補替換 */
        // 玩家列表
        _game.players = _recruit.players;
        // 狀態(已建立，等待時間到就開始 -> 進行中)
        _game.status = GameStatus.CREATED;
        // 將賽局加入賽局陣列
        games.push(_game);
        // 完成時 gameId+1
        gameId++;
    }

    /* 以下為函數中的查詢功能 */
    // 函數：查詢召集陣列裡狀態是召集中的id(會員限定)
    function getArrayRecruitedIds()
        public
        view
        onlyMember
        returns (uint256[] memory)
    {
        // 建立一個空陣列
        uint256[] memory _recruitIds = new uint256[](recruits.length);
        // 遍歷召集陣列
        for (uint256 i = 0; i < recruits.length; i++) {
            // 如果召集狀態為「召集中」，則將召集id放入陣列
            // 不用管陣列中的空值，因為陣列長度是固定的
            if (recruits[i].status == GameStatus.RECRUITED) {
                _recruitIds[i] = recruits[i].recruitId;
            }
        }
        // 回傳陣列
        return _recruitIds;
    }

    // 函數：查詢召集陣列(Array)裡狀態是審核中(Auditing)的id(場主限定)
    function getArrayAuditingIds()
        public
        view
        onlyHost
        returns (uint256[] memory)
    {
        // 建立一個空陣列
        uint256[] memory _recruitsId = new uint256[](recruits.length);
        // 遍歷召集陣列
        for (uint256 i = 0; i < recruits.length; i++) {
            // 如果召集狀態為「審核中」，則將召集id放入陣列
            if (recruits[i].status == GameStatus.AUDITING) {
                _recruitsId[i] = recruits[i].recruitId;
            }
        }
        return _recruitsId;
    }

    // 函數：查詢召集陣列中指定序號的召集資訊(會員限定)
    function getInfoFromRecruitArrayByRecruitId(uint256 _index)
        public
        view
        onlyMember
        returns (
            uint256,
            address,
            uint256,
            StartTime,
            EndTime,
            GameScale,
            Player[] memory,
            GameStatus
        )
    {
        // 透過序號取得召集(下標是序號-1)
        Recruit memory _recruit = recruits[_index - 1];
        // 回傳召集資訊
        return (
            _recruit.recruitId, // 召集id
            _recruit.host, // 場主
            _recruit.date, // 日期
            _recruit.startTime, // 開始時間
            _recruit.endTime, // 結束時間
            _recruit.scale, // 規模
            _recruit.players, // 玩家
            _recruit.status // 狀態
        );
    }

    // 函數：查詢召集映射中指定id的召集資訊(會員限定)
    function getInfoFromRecruitMappingByRecruitId(uint256 _recruitId)
        public
        view
        onlyMember
        returns (
            uint256,
            address,
            uint256,
            StartTime,
            EndTime,
            GameScale,
            Player[] memory,
            GameStatus
        )
    {
        // 透過召集id取得召集
        Recruit memory _recruit = idToRecruits[_recruitId];

        // 回傳召集資訊
        return (
            _recruit.recruitId, // 召集id
            _recruit.host, // 場主
            _recruit.date, // 日期
            _recruit.startTime, // 開始時間
            _recruit.endTime, // 結束時間
            _recruit.scale, // 規模
            _recruit.players, // 玩家列表
            _recruit.status // 狀態
        );
    }

    /************ 其他 ************/
    // 裝飾器：自己不在特定的召集中
    // modifier notInRecruit() {}

    // 函數：退出召集(會員限定)(若有候補，則將候補加入正選名單)
    // function quitRecruit() public onlyMember {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract MyEnum {
    // 會員狀態：未註冊、已註冊、停權中
    enum MemberStatus {
        UNREGISTERED,
        REGISTERED,
        BANNED
    }
    // 賽局底台大小
    enum GameScale {
        SMALL_31, // 0
        MEDIUM_51 // 1
    }

    // 賽局狀態：招募中、滿額審核中、已建立、等待開始、進行中、已結束
    enum GameStatus {
        RECRUITED,
        AUDITING,
        CREATED,
        WAITING_TO_START,
        PLAYING,
        ENDED
    }
    // 枚舉(開始時間)
    enum StartTime {
        AM_0000,
        AM_0100,
        AM_0200,
        AM_0300,
        AM_0400,
        AM_0500,
        AM_0600,
        PM_0700,
        PM_0800,
        PM_0900,
        PM_1000,
        PM_1100,
        PM_1200,
        PM_1300,
        PM_1400,
        PM_1500,
        PM_1600,
        PM_1700,
        PM_1800,
        PM_1900,
        PM_2000,
        PM_2100,
        PM_2200,
        PM_2300,
        PM_2400
    }

    // 枚舉(結束時間)
    enum EndTime {
        AM_0000,
        AM_0100,
        AM_0200,
        AM_0300,
        AM_0400,
        AM_0500,
        AM_0600,
        PM_0700,
        PM_0800,
        PM_0900,
        PM_1000,
        PM_1100,
        PM_1200,
        PM_1300,
        PM_1400,
        PM_1500,
        PM_1600,
        PM_1700,
        PM_1800,
        PM_1900,
        PM_2000,
        PM_2100,
        PM_2200,
        PM_2300,
        PM_2400,
        UNLIMITED
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;
/* (0-1)庫 import */
// 導入自訂套件
import "./MyEnum.sol";

// 會員系統合約
contract CMemberSystem is MyEnum {
    /* (0-1)庫 import */
    /* (0-1)介面 interface */
    /* (1-1)資料結構：枚舉 enum */
    /* (1-2)資料結構：結構 struct */
    /* (2)裝飾器 modifier */
    /* (3)事件 event */
    /* (4)常數、變數、陣列(array)、映射(mapping) */
    /* (5)建構子 constructor */
    /* (6)函數 function*/

    /* (1-2)資料結構：結構 struct */
    // 結構：會員(地址、狀態、召集紀錄、賽局紀錄)
    struct Member {
        address _memberAddress;
        MemberStatus _status;
        uint256[] _recruitIds;
        uint256[] _gameIds;
    }

    /* (2)裝飾器 modifier */
    // 裝飾器：沒註冊過
    modifier notRegistered() {
        require(addressToMembers[msg.sender].length == 0);
        _;
    }
    // 裝飾器：會員限定
    modifier onlyMember() {
        require(addressToMembers[msg.sender].length > 0);
        _;
    }

    /* (4)常數、變數、陣列(array)、映射(mapping) */
    // 常數：場主地址
    address public HOST_ADDRESS;
    // 會員陣列
    Member[] internal members;
    // 會員地址到會員索引的映射
    mapping(address => Member[]) internal addressToMembers;

    /* (5)建構子 constructor */
    // 建構子
    constructor() {
        //
        HOST_ADDRESS = msg.sender;
        // 建立場主
        Member memory _host = Member(
            msg.sender,
            MemberStatus.REGISTERED,
            new uint256[](0),
            new uint256[](0)
        );
        // 場主加入會員陣列
        members.push(_host);
        // 場主加入會員映射
        addressToMembers[msg.sender].push(members[members.length - 1]);
    }

    /* (6)函數 function*/
    // 函數：註冊
    function register() public notRegistered {
        // 1.檢查是否已註冊過會員(使用裝飾器)
        // 2.建立會員物件
        Member memory _member = Member(
            msg.sender,
            MemberStatus.REGISTERED,
            new uint256[](0),
            new uint256[](0)
        );
        // 3.新增會員到陣列
        members.push(_member);
        // 4.新增會員到映射
        addressToMembers[msg.sender].push(members[members.length - 1]);
    }

    // 函數：查看會員人數
    function countMembers() public view onlyMember returns (uint256) {
        return members.length;
    }

    // 函數：查看會員陣列
    function getMembersList() public view onlyMember returns (Member[] memory) {
        return members;
    }

    // 函數：傳回會員陣列的地址陣列
    function getMembersAddress()
        public
        view
        onlyMember
        returns (address[] memory)
    {
        // 1.建立地址陣列
        address[] memory _membersAddress = new address[](members.length);
        // 2.將會員陣列的地址填入地址陣列
        for (uint256 i = 0; i < members.length; i++) {
            _membersAddress[i] = members[i]._memberAddress;
        }
        return _membersAddress;
    }

    // 檢查(自己)是否為會員
    function isMember() public view returns (bool) {
        return addressToMembers[msg.sender].length > 0;
    }
}