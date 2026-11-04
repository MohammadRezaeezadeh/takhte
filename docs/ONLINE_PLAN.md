# Online plan (not implemented in v1)

## Principle
The server is authoritative and replays the same pure-Dart engine
(`lib/core`) — the server can run it directly with the Dart VM.

## Flow
1. Matchmaking creates a match with a server-chosen seed and `MatchConfig`.
2. Clients run the engine locally for responsiveness.
3. A client submits its turn as a batch of `GameAction`s plus the
   `stateHash` (FNV-1a of canonical state JSON) it reached.
4. The server applies the actions with `Engine.apply`; illegal → reject;
   hash mismatch → desync → server sends its authoritative state.
5. The server rolls dice: RNG state lives in `GameState`, so the server's copy is
   the only one that matters. Clients never send dice.
6. Opponent actions arrive through `RemoteTransport.nextActions`, consumed by
   `RemoteOpponent`, which implements the same `Opponent` interface the game flow
   already uses for AI and local humans.

## Protocol draft
```json
// client → server
{"t":"turn","match":"m_123","turn":17,"actions":[{"t":"roll"},{"t":"mv","m":{"f":13,"t":7,"d":6}},{"t":"end"}],"hash":305419896}
// server → client
{"t":"actions","match":"m_123","turn":18,"actions":[...],"hash":2271560481}
{"t":"desync","match":"m_123","state":{...GameState JSON...}}
```

## Hidden information
Landmines are hidden. Online, the server must redact the opponent's mine
effects (`EffectKind.landmine`) from state sent to the other client and
re-validate legality server-side (mines can change mid-turn legality).

## Anti-cheat
Because RNG and legality live on the server, a modified client cannot forge dice
or illegal moves; it can only resign or time out.
