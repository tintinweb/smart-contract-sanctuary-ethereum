contract XCMintTest {
    bool mintOpen;

    function mint(uint32 bot_type) external{
      require(!mintOpen);
    }

    function flipState(bool _state) external {
        mintOpen = _state;
    }

    function x(bool _state) external {
    }
    
    function o(bool _state) external {
    }

    function l(bool _state) external {
    }

    function a(bool _state) external {
    }
    
    function r(bool _state) external {
    }
    
}