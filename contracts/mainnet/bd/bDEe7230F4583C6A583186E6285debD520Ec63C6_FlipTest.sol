/**
*/
// I WROTE THIS BTW :keeny:
// KEENTOWNDAO
//CRYAIO SUCKS
//
contract FlipTest {
    bool paused;

    function setPaused(bool _state) external {
        paused = _state;
    }

    function testMint(uint32 bot_type) external{
      require(!paused);
    }
}