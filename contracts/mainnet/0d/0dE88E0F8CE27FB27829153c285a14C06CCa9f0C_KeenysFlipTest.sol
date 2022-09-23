/**
*/
//  I WROTE THIS BTW :keeny:

contract KeenysFlipTest {
    bool paused;
    
    function setPaused(bool _state) external {
        paused = _state;
    }

    function testMint(uint32 bot_type) external{
      require(!paused);
    }
}