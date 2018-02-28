pragma solidity ^0.4.0;
/*program for play a random song based on time*/
contract Random_music
{
    uint256 a;
    uint256 b;
    uint256 rem;
    string[] jukebox;
    function add_songs_to_playlist(string song)
    {
        jukebox.push(song);
    }
    function select_a_random_music() private returns(string)
    {
        b=now;
        if((a==0)||(a+30<b))//probably i play a cut song here!
        {
            a=now;
            b=a;
            do
            {
                rem+=a%10;
                if(rem>9)
                {
                    rem=((rem/10)%10)+rem%10;
                }
                a=a/10;
            }while(a!=0);
            a=b;
        }
        return jukebox[rem-1];
    }
    function playing_now() returns(string)
    {
        return select_a_random_music();
    }
}
