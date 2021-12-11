import React, { useEffect, useMemo, useRef, useState } from 'react'
import { Box } from 'grommet'
import { socket } from '../../helpers/client'
import { XTerm } from 'xterm-for-react'
import { FitAddon } from 'xterm-addon-fit'
import './shell.css'
import { normalizedThemes, savedTheme } from './themes'
import { ThemeSelector } from './ThemeSelector'

export function Shell({room, header, children: [title, sidebar], command}) {
  const xterm = useRef(null)
  const [channel, setChannel] = useState(null)
  const fitAddon = useMemo(() => new FitAddon(), [])
  const theme = savedTheme() || 'chalk'
  const themeStruct = normalizedThemes[theme]

  useEffect(() => {
    if (!xterm.current?.terminal) return
    fitAddon.fit()
    xterm.current.terminal.write("\r\n" + header + "\r\n\r\n")
    const params = command ? {command} : {}
    const chan = socket.channel(room, params)
    chan.onError(console.log)
    chan.on("stdo", ({message}) => xterm.current?.terminal?.write(message))
    chan.join()
    setChannel(chan)
    return () => chan.leave()
  }, [room, xterm, fitAddon, command])

  return (
    <Box fill background='backgroundColor'>
      <Box flex={false} pad='small' direction='row' align='center'>
        {title}
        <ThemeSelector theme={theme} />
      </Box>
      <Box fill border direction='row'>
        {sidebar}
        <Box fill pad='small' background={themeStruct.background}>
          <XTerm 
            className='terminal'
            ref={xterm}
            addons={[fitAddon]}
            options={{theme: themeStruct}}
            onData={(text) => channel.push("command", {cmd: text})} />
        </Box>
      </Box>
    </Box>
  )
}