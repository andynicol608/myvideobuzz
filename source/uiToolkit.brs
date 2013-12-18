
'  uitkDoPosterMenu
'
'    Display "menu" items in a Poster Screen.
'
Function uitkPreShowPosterMenu(ListStyle="flat-category" as String, breadA = "Home", breadB = invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    if (breadA <> invalid and breadB <> invalid) then
        screen.SetBreadcrumbText(breadA, breadB)
    else if (breadA <> invalid and breadB = invalid) then
        screen.SetBreadcrumbText(breadA, "")
        screen.SetTitle(breadA)
    end if

    if (ListStyle = "" OR ListStyle = invalid) then
        ListStyle = "flat-category"
    end if

    screen.SetListStyle(ListStyle)
    screen.SetListDisplayMode("scale-to-fit")
    ' screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function


Function uitkDoPosterMenu(posterdata, screen, onselect_callback = invalid, onplay_func = invalid) As Integer
    if (type(screen) <> "roPosterScreen") then
        'print "illegal type/value for screen passed to uitkDoPosterMenu()"
        return -1
    end if

    screen.SetContentList(posterdata)
    idx% = 0
    while (true)
        msg = wait(2000, screen.GetMessagePort())

        'print "uitkDoPosterMenu | msg type = ";type(msg)
        if (type(msg) = "roPosterScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1 = onselect_callback[1]
                        userdata2 = onselect_callback[2]
                        f = onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            else if (msg.isListItemFocused()) then
                idx% = msg.GetIndex()
            else if (msg.isRemoteKeyPressed()) then
                ' If the play button is pressed on the video list, and the onplay_func is valid, play the video
                if (onplay_func <> invalid AND msg.GetIndex() = 13) then
                    onplay_func(posterdata[idx%])
                end if
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
End Function


Function uitkPreShowListMenu(breadA=invalid, breadB=invalid) As Object
    port = CreateObject("roMessagePort")
    screen = CreateObject("roListScreen")
    screen.SetMessagePort(port)
    if (breadA <> invalid and breadB <> invalid) then
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    'screen.SetListStyle("flat-category")
    'screen.SetListDisplayMode("best-fit")
    'screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function


Function uitkDoListMenu(posterdata, screen, onselect_callback=invalid) As Integer

    if (type(screen) <> "roListScreen") then
        'print "illegal type/value for screen passed to uitkDoListMenu()"
        return -1
    end if

    screen.SetContent(posterdata)

    while (true)
        msg = wait(2000, screen.GetMessagePort())

        if (type(msg) = "roListScreenEvent") then
            'print "event.GetType()=";msg.GetType(); " Event.GetMessage()= "; msg.GetMessage()
            if (msg.isListItemSelected()) then
                if (onselect_callback <> invalid) then
                    selecttype = onselect_callback[0]
                    if (selecttype = 0) then
                        this = onselect_callback[1]
                        selected_callback = onselect_callback[msg.GetIndex() + 2]
                        if (islist(selected_callback)) then
                            f = selected_callback[0]
                            userdata1 = selected_callback[1]
                            userdata2 = selected_callback[2]
                            userdata3 = selected_callback[3]

                            if (userdata1 = invalid) then
                                this[f]()
                            else if (userdata2 = invalid) then
                                this[f](userdata1)
                            else if (userdata3 = invalid) then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if (selected_callback = "return") then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if (selecttype = 1) then
                        userdata1=onselect_callback[1]
                        userdata2=onselect_callback[2]
                        f=onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if (msg.isScreenClosed()) then
                return -1
            end if
        else if (msg = invalid) then
            CheckForMCast()
        end if
    end while
End Function


Function uitkDoCategoryMenu(categoryList, screen, content_callback = invalid, onclick_callback = invalid, onplay_func = invalid) As Integer
    'Set current category to first in list
    category_idx = 0
    contentlist = []

    screen.SetListNames(categoryList)
    contentdata1 = content_callback[0]
    contentdata2 = content_callback[1]
    content_f = content_callback[2]

    contentlist = content_f(contentdata1, contentdata2, 0)

    if (contentlist.Count() = 0) then
        screen.SetContentList([])
        screen.clearmessage()
        screen.showmessage("No viewable content in this section")
    else
        screen.SetContentList(contentlist)
        screen.clearmessage()
    end if
    screen.Show()
    idx% = 0
    contentdata1 = invalid
    contentdata2 = invalid
    content_f = invalid
    ' Tracks when the category was selected
    category_time = CreateObject("roTimespan")
    ' Tracks the amount of time between CheckForMCast calls
    multicast_time = CreateObject("roTimespan")
    ' This flag is used to determine when a query to the server for category data
    ' should actually occur, rather than every time a category was selected
    awaiting_timeout = false
    ' Default the multicast timer
    multicast_time.Mark()
    while (true)
        msg = wait(500, screen.GetMessagePort())
        if (type(msg) = "roPosterScreenEvent") then
            if (msg.isListFocused()) then
                category_idx = msg.GetIndex()
                contentdata1 = content_callback[0]
                contentdata2 = content_callback[1]
                content_f = content_callback[2]
                ' Track that a timeout is being awaited
                awaiting_timeout = true
                ' Mark the time that the category was selected
                category_time.Mark()
            else if (msg.isListItemSelected()) then
                userdata1 = onclick_callback[0]
                userdata2 = onclick_callback[1]
                content_f = onclick_callback[2]

                ' Reset the awaiting_timeout flag if an item is clicked
                awaiting_timeout = false
                category_time.Mark()

                contentData = content_f(userdata1, userdata2, contentlist, category_idx, msg.GetIndex())
                if ( contentData.isContentList = true ) then
                    contentlist = contentData.content
                    if (contentlist.Count() <> 0) then
                        if ( contentlist[0]["action"] <> invalid AND contentlist.Count() > 1 ) then
                            screen.SetFocusedListItem(1)
                        else
                            screen.SetFocusedListItem(0)
                        end if
                        screen.SetContentList(contentlist)
                        'screen.SetFocusedListItem(msg.GetIndex())
                    end if
                end if
            else if (msg.isListItemFocused()) then
                idx% = msg.GetIndex()
            else if (msg.isScreenClosed()) then
                return -1
            else if (msg.isRemoteKeyPressed()) then
                ' If the play button is pressed on the video list, and the onplay_func is valid, play the video
                if (onplay_func <> invalid AND msg.GetIndex() = 13) then
                    onplay_func(contentlist[idx%])
                end if
            end if
        else if (msg = invalid) then
            ' This addresses the issue when trying to scroll quickly through the category list,
            ' previously, each category would queue a request to YouTube, and the user would have to wait when they
            ' reached their desired category for the correct video list to load (could be painful with a lot of categories)
            if (awaiting_timeout = true AND category_time.TotalMilliseconds() > 900) then
                awaiting_timeout = false
                contentlist = content_f(contentdata1, contentdata2, category_idx)
                if (contentlist.Count() = 0) then
                    screen.SetContentList([])
                    screen.ShowMessage("No viewable content in this section")
                else
                    screen.SetContentList(contentlist)
                    screen.SetFocusedListItem(0)
                end if
            else if (multicast_time.TotalSeconds() > 2) then
                ' Don't allow the CheckForMCast function to run too much due to the category query change
                multicast_time.Mark()
                CheckForMCast()
            end if
        end If
    end while
End Function

Sub uitkDoMessage(message, screen)
    screen.showMessage(message)
    while (true)
        msg = wait(0, screen.GetMessagePort())
        if (msg.isScreenClosed()) then
            return
        end if
    end while
End Sub