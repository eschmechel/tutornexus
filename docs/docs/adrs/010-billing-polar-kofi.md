---
title: ADR-010 - Billing via Polar, Donations via Ko-fi
description: Polar subscriptions and Ko-fi donation links.
sidebar_position: 11
---

# ADR-010: Billing via Polar, Donations via Ko-fi

- Status: Accepted
- Date: 2026-02-04

## Context

We want subscriptions with minimal operational overhead and a simple path for donations.

## Decision

- Use Polar for subscriptions.
- Use Ko-fi for donation links.

## Consequences

- Quotas must integrate with subscription status.
- Use Polar's [Hono Adapter](https://polar.sh/docs/integrate/sdk/adapters/hono)
- Donations remain out-of-band (no entitlement changes implied).

## Alternatives considered

- Stripe direct: flexible but higher implementation + compliance burden.
