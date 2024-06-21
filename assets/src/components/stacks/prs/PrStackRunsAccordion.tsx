import {
  Accordion,
  ArrowTopRightIcon,
  DropdownArrowIcon,
  EmptyState,
  IconFrame,
  useSetBreadcrumbs,
} from '@pluralsh/design-system'
import { PullRequestFragment, useStackRunsQuery } from 'generated/graphql'
import { useMemo } from 'react'
import { Link, useParams } from 'react-router-dom'

import { isEmpty } from 'lodash'

import styled, { useTheme } from 'styled-components'

import { PrStatusChip } from 'components/pr/queue/PrQueueColumns'

import { StackRunsScroller } from '../runs/StackRunsScroller'
import { getBreadcrumbs } from '../Stacks'

const pollInterval = 5 * 1000

// can't really make this dynamic with the current scroller component
const ACCORDION_TABLE_HEIGHT = '300px'

export function PrStackRunsAccordion({
  pr,
  isOpen,
  toggleOpen,
}: {
  pr: PullRequestFragment
  isOpen: boolean
  toggleOpen: (open: boolean) => void
}) {
  const theme = useTheme()
  const { stackId = '' } = useParams()

  useSetBreadcrumbs(
    useMemo(() => [...getBreadcrumbs(stackId), { label: 'prs' }], [stackId])
  )

  const queryResult = useStackRunsQuery({
    variables: { id: stackId, pullRequestId: pr.id },
    fetchPolicy: 'cache-and-network',
    pollInterval,
    skip: !isOpen,
  })

  return (
    <Accordion
      unstyled
      isOpen={isOpen}
      triggerButton={
        <PrStackRunsAccordionTrigger
          isOpen={isOpen}
          toggleOpen={toggleOpen}
          pr={pr}
        />
      }
      css={{
        width: '100%',
      }}
    >
      {queryResult.data ? (
        !isEmpty(queryResult.data.infrastructureStack?.runs) ? (
          <ScrollerWrapperSC>
            <StackRunsScroller
              entryStyles={{
                paddingLeft: `${theme.spacing.xxxlarge}px`,
                background: theme.colors['fill-two'],
                borderBottom: theme.borders['fill-two'],
                '&:hover': { backgroundColor: theme.colors['fill-two-hover'] },
              }}
              queryResult={queryResult}
            />
          </ScrollerWrapperSC>
        ) : (
          <EmptyState message="No runs found." />
        )
      ) : null}
    </Accordion>
  )
}

function PrStackRunsAccordionTrigger({
  pr,
  isOpen,
  toggleOpen,
}: {
  pr: PullRequestFragment
  isOpen: boolean
  toggleOpen: (open: boolean) => void
}) {
  return (
    <TriggerWrapperSC onClick={() => toggleOpen(!isOpen)}>
      <TriggerArrowSC
        size="medium"
        className={isOpen ? 'open' : ''}
      />
      <span>{pr.title}</span>
      <PrStatusChip status={pr.status} />
      {pr.creator && <span>created by {pr.creator}</span>}
      <IconFrame
        icon={<ArrowTopRightIcon />}
        as={EndLinkSC}
        to={pr.url}
      />
    </TriggerWrapperSC>
  )
}

const EndLinkSC = styled(Link)(({ theme }) => ({
  marginLeft: 'auto',
  '&:hover': {
    background: theme.colors['fill-two-hover'],
  },
}))

const TriggerWrapperSC = styled.div(({ theme }) => ({
  display: 'flex',
  alignItems: 'center',
  gap: theme.spacing.large,
  padding: `${theme.spacing.medium}px`,
  cursor: 'pointer',
  background: theme.colors['fill-one'],
  '&:hover': {
    background: theme.colors['fill-one-hover'],
  },
}))

const TriggerArrowSC = styled(DropdownArrowIcon)(({ theme }) => ({
  position: 'relative',
  transition: 'transform 0.25s ease',
  transform: 'rotate(-90deg)',
  width: theme.spacing.medium,
  '&.open': { transform: 'rotate(0deg)' },
}))

const ScrollerWrapperSC = styled.div(({ theme }) => ({
  padding: `${theme.spacing.xsmall}px 0`,
  background: theme.colors['fill-two'],
  height: ACCORDION_TABLE_HEIGHT,
  position: 'relative', // for the "back to top" button to position correctly
}))
